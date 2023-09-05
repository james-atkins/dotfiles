// Launch apps in the app.slice using swaymsg and systemd.
// See https://systemd.io/DESKTOP_ENVIRONMENTS/

package main

import (
	"context"
	"fmt"
	"math/rand"
	"os"
	"os/signal"
	"path/filepath"
	"strings"
	"time"

	"github.com/alessio/shellescape"
	"github.com/coreos/go-systemd/unit"
	"github.com/joshuarubin/go-sway"
)

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt)
	defer stop()

	ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()

	if err := run(ctx); err != nil {
		fmt.Printf("error: %+v\n", err)
		os.Exit(1)
	}
}

func run(ctx context.Context) error {
	args := os.Args[1:]

	if len(args) == 0 {
		return fmt.Errorf("%s requires command (and optionally arguments) to execute", filepath.Base(os.Args[0]))
	}

	appName := filepath.Base(args[0])
	unitName := fmt.Sprintf("app-%s-%s", unit.UnitNameEscape(appName), RandomString())

	command := strings.Join(
		[]string{
			"exec",
			fmt.Sprintf("systemd-run --user --scope --slice=app.slice --unit=%s --collect", unitName),
			shellescape.QuoteCommand(args),
		},
		" ")

	cli, err := sway.New(ctx)
	if err != nil {
		return err
	}

	replies, err := cli.RunCommand(ctx, command)
	if err != nil {
		return err
	}

	for _, reply := range replies {
		if !reply.Success {
			return fmt.Errorf("sway exec failed: %s", reply.Error)
		}
	}

	return nil
}

const letterBytes = "abcdefghijklmnopqrstuvwxyz0123456789"

func RandomString() string {
	var b [32]byte
	for i := range b {
		b[i] = letterBytes[rand.Intn(len(letterBytes))]
	}
	return string(b[:])
}
