package main

import (
	"fmt"

	"github.com/kmf/dankfm/core/internal/openpath"
	"github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
	Use:     "dfm",
	Short:   "DankFM — miller-column file manager",
	Long:    "DankFM is a miller-column file manager for the dank desktop. Closing the window hides it; dfm kill quits.",
	Args:    cobra.MaximumNArgs(1),
	PreRunE: shellApp.ResolveConfig,
	RunE: func(_ *cobra.Command, args []string) error {
		if len(args) == 0 {
			return shellApp.CallOrLaunch("ui.show", nil)
		}
		return browseArg(args[0])
	},
}

var versionCmd = &cobra.Command{
	Use:   "version",
	Short: "Show version information",
	RunE: func(_ *cobra.Command, _ []string) error {
		fmt.Printf("dfm %s (commit %s, built %s)\n", Version, Commit, BuildTime)
		return nil
	},
}

func init() {
	rootCmd.PersistentFlags().StringVarP(shellApp.CustomConfigVar(), "config", "c", "", "Path to a UI config dir (containing shell.qml) instead of the embedded UI (env: DANKFM_SHELL_DIR)")

	rootCmd.AddCommand(versionCmd)
	rootCmd.AddCommand(shellApp.Commands()...)
	rootCmd.AddCommand(showCmd)
	rootCmd.AddCommand(toggleCmd)
	rootCmd.AddCommand(openCmd)
	rootCmd.AddCommand(statusCmd)
}

func browseArg(raw string) error {
	path, err := openpath.Resolve(raw)
	if err != nil {
		return err
	}
	return shellApp.CallOrLaunch("ui.browse", map[string]any{"path": path})
}
