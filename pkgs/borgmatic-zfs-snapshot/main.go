package main

import (
	"bufio"
	"bytes"
	"fmt"
	"log"
	"os"
	"os/exec"
	"os/signal"
	"runtime"
	"sort"
	"strings"
	"syscall"

	"github.com/google/uuid"
	"golang.org/x/sys/unix"
)

type stringFlags struct {
	set    bool
	Values []string
}

func newStringFlags(defaults ...string) stringFlags {
	return stringFlags{
		set:    false,
		Values: defaults,
	}
}

func (sf *stringFlags) String() string {
	return "[" + strings.Join(sf.Values, ", ") + "]"
}

func (sf *stringFlags) Set(value string) error {
	if !sf.set {
		sf.set = true
		sf.Values = []string{value}
	} else {
		sf.Values = append(sf.Values, value)
	}
	return nil
}

type ZFS struct {
	zfsPath   string
	zpoolPath string
}

func NewZFS() (*ZFS, error) {
	zfsPath, err := exec.LookPath("zfs")
	if err != nil {
		return nil, err
	}

	zpoolPath, err := exec.LookPath("zpool")
	if err != nil {
		return nil, err
	}

	// Test that zfs and zpool commands work, i.e. that the kernel modules are loaded
	if err := exec.Command(zfsPath, "version").Run(); err != nil {
		return nil, err
	}

	if err := exec.Command(zpoolPath, "version").Run(); err != nil {
		return nil, err
	}

	return &ZFS{zfsPath: zfsPath, zpoolPath: zpoolPath}, nil
}

func (zfs *ZFS) GetDatasetAndChildren(dataset string) ([]string, error) {
	cmd := exec.Command(zfs.zfsPath, "list", "-H", "-o", "name", "-t", "filesystem", "-r", dataset)
	stderr := &strings.Builder{}
	cmd.Stderr = stderr
	output, err := cmd.Output()
	if err != nil {
		if exitError, ok := err.(*exec.ExitError); ok {
			if exitError.ExitCode() > 0 {
				return nil, fmt.Errorf("zfs list failed: %s", stderr.String())
			}
		}
		return nil, err
	}

	var datasets []string

	scanner := bufio.NewScanner(bytes.NewReader(output))
	for scanner.Scan() {
		text := scanner.Text()
		datasets = append(datasets, text)
	}

	if err := scanner.Err(); err != nil {
		return nil, err
	}

	return datasets, nil
}

// Get the mountpoints of the given datasets
// Note that some datasets may not be mounted so the length of the returned map may be smaller
// than the input list
func (zfs *ZFS) GetMountpoints(datasets []string) (map[string]string, error) {
	if len(datasets) == 0 {
		return nil, nil
	}

	datasetsLookup := make(map[string]struct{})
	for _, dataset := range datasets {
		datasetsLookup[dataset] = struct{}{}
	}

	cmd := exec.Command(zfs.zfsPath, "mount")
	output, err := cmd.Output()
	if err != nil {
		return nil, err
	}

	// map of dataset:mountpoint
	mountpoints := make(map[string]string)

	scanner := bufio.NewScanner(bytes.NewReader(output))
	for scanner.Scan() {
		line := scanner.Text()
		fields := strings.Fields(line)
		if len(fields) != 2 {
			return nil, fmt.Errorf("zfs mount returned unexpected data: %s", line)
		}

		dataset, mountpoint := fields[0], fields[1]
		if _, ok := datasetsLookup[dataset]; ok {
			mountpoints[dataset] = mountpoint
		}
	}

	if err := scanner.Err(); err != nil {
		return nil, err
	}

	return mountpoints, nil
}

func (zfs *ZFS) CreateSnapshot(dataset string, snapshot string) error {
	datasetAndSnapshot := fmt.Sprintf("%s@%s", dataset, snapshot)

	cmd := exec.Command(zfs.zfsPath, "snapshot", "-r", datasetAndSnapshot)
	stderr := &strings.Builder{}
	cmd.Stderr = stderr

	if err := cmd.Run(); err != nil {
		if exitError, ok := err.(*exec.ExitError); ok {
			if exitError.ExitCode() > 0 {
				return fmt.Errorf("zfs snapshot failed: %s", stderr.String())
			}
		}
		return err
	}

	return nil
}

func (zfs *ZFS) RecursivelyDestroySnapshots(dataset string, snapshot string) error {
	datasetAndSnapshot := fmt.Sprintf("%s@%s", dataset, snapshot)

	cmd := exec.Command(zfs.zfsPath, "destroy", "-r", datasetAndSnapshot)
	stderr := &strings.Builder{}
	cmd.Stderr = stderr

	if err := cmd.Run(); err != nil {
		if exitError, ok := err.(*exec.ExitError); ok {
			if exitError.ExitCode() > 0 {
				return fmt.Errorf("zfs destroy failed: %s", stderr.String())
			}
		}
		return err
	}

	return nil
}

func RunBorgmatic(mountpoints map[string]string) error {
	errC := make(chan error, 1)

	go func() {
		err := runBorgmatic(mountpoints)
		errC <- err
	}()

	return <-errC
}

func runBorgmatic(mountpoints map[string]string) error {
	// Sort by mountpoint first so the snapshots are mounted in the right order
	mountpointsReverse := make(map[string]string)
	ms := make([]string, 0, len(mountpoints))
	for datasetAndSnapshot, mountpoint := range mountpoints {
		mountpointsReverse[mountpoint] = datasetAndSnapshot
		ms = append(ms, mountpoint)
	}
	sort.Strings(ms)

	// Create a new mount namespace on a locked thread
	runtime.LockOSThread()

	if err := syscall.Unshare(syscall.CLONE_NEWNS); err != nil {
		return fmt.Errorf("unshare failed: %w", err)
	}
	// https://go-review.googlesource.com/c/go/+/38471
	if err := syscall.Mount("", "/", "", syscall.MS_PRIVATE|syscall.MS_REC, ""); err != nil {
		return fmt.Errorf("mount failed: %w", err)
	}
	// Mount the snapshots
	for _, mountpoint := range ms {
		datasetAndSnapshot := mountpointsReverse[mountpoint]
		if err := syscall.Mount(datasetAndSnapshot, mountpoint, "zfs", syscall.MS_RDONLY, ""); err != nil {
			return err
		}
		defer func(mountpoint string) {
			if err := syscall.Unmount(mountpoint, syscall.MNT_DETACH); err != nil {
				log.Printf("Error unmounting: %+v", err)
			}
		}(mountpoint)
	}

	// Listen for signals
	signalC := make(chan os.Signal, 1)
	signal.Notify(signalC, os.Interrupt, syscall.SIGTERM)
	defer func() {
		signal.Stop(signalC)
		close(signalC)
	}()

	// Now run borgmatic
	// Note: the process will inherit this goroutine's mount namespace
	// https://pkg.go.dev/os#StartProcess
	cmd := exec.Command("@BORGMATIC@", os.Args[1:]...)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.SysProcAttr = &syscall.SysProcAttr{
		Setpgid: true,
	}
	if unix.Prctl(unix.PR_SET_CHILD_SUBREAPER, 1, 0, 0, 0) != nil {
		return nil
	}

	if err := cmd.Start(); err != nil {
		return fmt.Errorf("error starting command: %w", err)
	}

	go func() {
		for sig := range signalC {
			syscallSig, ok := sig.(syscall.Signal)
			if !ok {
				log.Printf("cannot convert %s into syscall signal", sig)
				continue
			}

			if err := syscall.Kill(-cmd.Process.Pid, syscallSig); err != nil {
				log.Printf("cannot send signal %s to child processes", sig)
			}
		}
	}()

	var waitErr error
	if err := cmd.Wait(); err != nil {
		waitErr = fmt.Errorf("error running borgmatic: %w", err)
	}

	// Wait for all child processes to terminate. This is because borgmatic starts borg which starts
	// an SSH client and we need all the processes to be terminated so the ZFS snapshot can be unmounted.
	var ws unix.WaitStatus
	for {
		pid, err := unix.Wait4(-1, &ws, unix.WALL, nil)
		if err != nil {
			if err == unix.ECHILD { // no more child processes
				break
			}
			return fmt.Errorf("error waiting for child processes: %w", err)
		}
		if pid == cmd.Process.Pid { // command process has exited
			break
		}
	}

	return waitErr
}

func readConfig() ([]string, error) {
	var snapshots []string
	
	f, err := os.Open("/etc/borgmatic/zfs-snapshots")
	if err != nil {
		return nil, fmt.Errorf("cannot read config: %w", err)
	}
	defer f.Close()

	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		snapshots = append(snapshots, scanner.Text())
	}

	if err := scanner.Err(); err != nil {
		return nil, err
	}

	return snapshots, nil
}

func main() {
	if err := run(true); err != nil {
		fmt.Fprintf(os.Stderr, "%+v\n", err)
		os.Exit(1)
	}
}

func run(verbose bool) (err error) {
	if os.Geteuid() != 0 {
		return fmt.Errorf("Must be root")
	}

	zfs, err := NewZFS()
	if err != nil {
		return err
	}

	snapshot := fmt.Sprintf("borgmatic_%s", uuid.NewString())

	// Read the ZFS datasets to take recursive snapshots of before running borgmatic.
	// In future, this won't be necessary as we will work out which datasets to take snapshots of by
	// examining the borgmatic config file.
	datasetsToRecursivelySnapshot, err := readConfig()
	if err != nil {
		return err
	}

	var snapshottedDatasets []string

	for _, dataset := range datasetsToRecursivelySnapshot {
		// Create a recursive snapshot of each toplevel dataset
		if err := zfs.CreateSnapshot(dataset, snapshot); err != nil {
			return err
		}

		defer func(dataset string) {
			errSnapDestroy := zfs.RecursivelyDestroySnapshots(dataset, snapshot)
			if errSnapDestroy != nil {
				if err == nil {
					err = errSnapDestroy
				} else {
					log.Printf("Failed to destroy snapshot %s@%s: %s", dataset, snapshot, errSnapDestroy)
				}
			}
		}(dataset)

		// Get the datasets (including the child datasets) that we have just created a snapshot for
		// E.g. zfs list -t filesystem -r tank
		ds, err := zfs.GetDatasetAndChildren(dataset)
		if err != nil {
			return err
		}
		snapshottedDatasets = append(snapshottedDatasets, ds...)
	}

	if verbose && len(snapshottedDatasets) > 0 {
		fmt.Printf("Created snapshot %s on datasets:\n", snapshot)
		for _, dataset := range snapshottedDatasets {
			fmt.Printf("  • %s\n", dataset)
		}
	}

	// Of the datasets that we have taken a snapshot of, get the ones that are currently mounted
	mountpoints, err := zfs.GetMountpoints(snapshottedDatasets)
	if err != nil {
		return err
	}

	// Now create the mountpoints of the snapshots
	snapshotMountpoints := make(map[string]string)
	for dataset, mountpoint := range mountpoints {
		snapshotMountpoints[fmt.Sprintf("%s@%s", dataset, snapshot)] = mountpoint
	}

	if verbose && len(snapshotMountpoints) > 0 {
		fmt.Println("Mountpoints: ")
		for snapshot, mountpoint := range snapshotMountpoints {
			fmt.Printf("  • %s ⇛ %s\n", snapshot, mountpoint)
		}
	}

	if err := RunBorgmatic(snapshotMountpoints); err != nil {
		return err
	}

	return nil
}
