package main

import (
	"encoding/json"
	"fmt"
	"os"

	dankipc "github.com/AvengeMedia/dankgo/ipc"
	"github.com/spf13/cobra"
)

var showCmd = &cobra.Command{
	Use:     "show",
	Short:   "Show the window, launching dfm if it is not running",
	PreRunE: shellApp.ResolveConfig,
	RunE: func(_ *cobra.Command, _ []string) error {
		return shellApp.CallOrLaunch("ui.show", nil)
	},
}

var toggleCmd = &cobra.Command{
	Use:     "toggle",
	Short:   "Toggle window visibility, launching dfm if it is not running",
	PreRunE: shellApp.ResolveConfig,
	RunE: func(_ *cobra.Command, _ []string) error {
		return shellApp.CallOrLaunch("ui.toggle", nil)
	},
}

var openCmd = &cobra.Command{
	Use:     "open [path]",
	Short:   "Show the window at a path or file:// URI",
	PreRunE: shellApp.ResolveConfig,
	Args:    cobra.ExactArgs(1),
	RunE: func(_ *cobra.Command, args []string) error {
		return browseArg(args[0])
	},
}

var statusCmd = &cobra.Command{
	Use:   "status",
	Short: "Print the directory currently on screen",
	RunE: func(_ *cobra.Command, _ []string) error {
		socketPath, err := dankipc.FindRunningSocket("dankfm")
		if err != nil {
			return err
		}
		client, err := dankipc.Dial(socketPath)
		if err != nil {
			return err
		}
		defer client.Close()
		resp, err := client.Call(dankipc.Request{ID: 1, Method: "ui.status"})
		if err != nil {
			return err
		}
		if resp.Error != "" {
			return fmt.Errorf("%s", resp.Error)
		}
		if resp.Result == nil {
			return nil
		}
		raw, err := json.Marshal(resp.Result)
		if err != nil {
			return err
		}
		var out struct {
			Path string `json:"path"`
		}
		if err := json.Unmarshal(raw, &out); err != nil {
			fmt.Fprintln(os.Stdout, string(raw))
			return nil
		}
		fmt.Fprintln(os.Stdout, out.Path)
		return nil
	},
}
