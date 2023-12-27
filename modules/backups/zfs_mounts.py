#! @shell@

import csv
import ctypes.util
import io
import os
import subprocess

from typing import NamedTuple, Optional, Union

# TODO: zfs holds during backups

MS_RDONLY = 1
MS_BIND = 4096

libc = ctypes.CDLL(ctypes.util.find_library("c"), use_errno=True)

libc.mount.argtypes = [ctypes.c_char_p,   # source
                       ctypes.c_char_p,   # target
                       ctypes.c_char_p,   # filesystem_type
                       ctypes.c_ulong,    # mount_flags
                       ctypes.c_char_p]   # data


def mount_zfs_snapshot(snapshot, target):
    ret = libc.mount(snapshot.encode(), target.encode(), "zfs".encode(), MS_RDONLY, None)
    if ret < 0:
        errno = ctypes.get_errno()
        raise OSError(errno, f"Error mounting snapshot {snapshot} on {target}: {os.strerror(errno)}")


def mount_bind(source, target):
    ret = libc.mount(source.encode(), target.encode(), None, MS_BIND, None)
    if ret < 0:
        errno = ctypes.get_errno()
        raise OSError(errno, f"Error bind mounting {source} on {target}: {os.strerror(errno)}")


def mount_tmpfs(target):
    ret = libc.mount("tmpfs".encode(), target.encode(), "tmpfs".encode(), 0, "rw,size=32M".encode())
    if ret < 0:
        errno = ctypes.get_errno()
        raise OSError(errno, f"Error  mounting tmpfs on {target}: {os.strerror(errno)}")


def get_zfs_mounts():
    """ Return a dictionary of currently mounted ZFS volumes and their mount points. """
    mounts = {}

    process = subprocess.run(["zfs", "mount"], stdout=subprocess.PIPE, check=True, encoding="utf-8")
    csv_reader = csv.reader(io.StringIO(process.stdout), delimiter=' ', skipinitialspace=True)
    for volume, mount_point in csv_reader:
        # If there are multiple entries for a ZFS volume, then these are most likely bind mounts.
        # zfs mount seems to return mounts in the order that they were created, so the bind mounts
        # are the second, third etc entries. So we skip any repeats of volumes.
        if volume not in mounts:
            mounts[volume] = mount_point

    return mounts


def get_most_recent_snapshot(volume: str) -> Optional[str]:
    """ Return the most recent snapshot of the given ZFS volume or None if no snapshot exists. """
    # TODO: Check whether the snapshot is recent enough
    process = subprocess.run(
        ["zfs", "list", "-t", "snapshot", "-o", "name", "-s", "creation", "-H", "-p", volume],
        stdout=subprocess.PIPE,
        check=True,
        encoding="utf-8"
    )

    csv_reader = csv.reader(io.StringIO(process.stdout), delimiter='\t', skipinitialspace=True)

    # Get last (i.e. most recent) snapshot as zfs list is sorting by creation
    newest_snapshot = None
    for snapshot, in csv_reader:
        svolume, ssnapshot = snapshot.split("@")
        if ssnapshot.startswith("zrepl_"):
            newest_snapshot = snapshot

    return newest_snapshot


def get_zrepl_mounts():
    mounts = {}

    process = subprocess.run(
        ["zfs", "list", "-t", "filesystem", "-o", "name", "-H", "-r", "tank/zrepl"],
        stdout=subprocess.PIPE,
        check=True,
        encoding="utf-8"
    )

    csv_reader = csv.reader(io.StringIO(process.stdout), delimiter='\t', skipinitialspace=True)
    for filesystem, in csv_reader:
        if filesystem == "tank/zrepl":
            continue

        assert filesystem.startswith("tank/zrepl/")
        try:
            machine, machine_dataset = filesystem.removeprefix("tank/zrepl/").split("/", 1)
        except ValueError:
            continue
        else:
            machine_dataset = machine_dataset.replace("/", "-")
            mounts[filesystem] = f"/zrepl/{machine}/{machine_dataset}"

    return mounts


class BindMount(NamedTuple):
    source: str
    target: str


class SnapshotMount(NamedTuple):
    volume: str
    mount_point: str
    snapshot: Optional[str]


class TmpfsMount(NamedTuple):
    target: str


def make_mount_points() -> list[Union[BindMount, SnapshotMount]]:
    # Mount borg/borgmatic state folders to /run/ so borg and borgmatic can write to them even when
    # a snapshot of the ZFS volume that they are on is mounted, and therefore is read-only.
    os.makedirs("/run/backups/state", exist_ok=True)
    os.makedirs("/run/backups/cache", exist_ok=True)
    mount_points = [BindMount("@stateDir@", "/run/backups/state"),
                    BindMount("@cacheDir@", "/run/backups/cache")]

    zfs_mounts = get_zfs_mounts()
    for volume, mount_point in zfs_mounts.items():
        snapshot = get_most_recent_snapshot(volume)
        mount_points.append(SnapshotMount(volume, mount_point, snapshot))

    zfs_mounts = get_zrepl_mounts()
    if zfs_mounts:
        os.makedirs("/zrepl", exist_ok=True)
        mount_points.append(TmpfsMount("/zrepl"))

        for volume, mount_point in zfs_mounts.items():
            snapshot = get_most_recent_snapshot(volume)
            mount_points.append(SnapshotMount(volume, mount_point, snapshot))

    return mount_points


if __name__ == "__main__":
    # TODO: Check that we are running in a private mount namespace (e.g. PrivateMounts=true)
    # TODO: Check root
    mount_points = make_mount_points()

    if len(mount_points) > 0:
        print("Mounting the following snapshots:")

    for mount in mount_points:
        if isinstance(mount, SnapshotMount):
            volume, mount_point, snapshot = mount

            if mount_point == "/":
                # Don't mount the snapshot of root filesystem as that will screw lots of things up.
                # Nothing is directly stored on here anyway.
                continue

            elif snapshot is None:
                continue

            else:
                if not os.path.exists(mount_point):
                    os.makedirs(mount_point)
                mount_zfs_snapshot(snapshot, mount_point)
                print(f"  • {snapshot} ⇛ {mount_point}")

        elif isinstance(mount, BindMount):
            source, target = mount

            mount_bind(source, target)
            print(f"  • {source} ⇛ {target}")

        elif isinstance(mount, TmpfsMount):
            mount_tmpfs(mount.target)
            print(f"  • tmpfs ⇛ {mount.target}")

        else:
            raise ValueError(f"unexpected mount: {mount}")
