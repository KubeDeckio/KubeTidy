package cli

import (
	"fmt"
	"io"
	"path/filepath"
	"strings"
	"time"

	"github.com/KubeDeckio/KubeTidy/internal/kubeconfig"
	"github.com/spf13/cobra"
)

type options struct {
	kubeConfigPath      string
	exclusionList       []string
	backup              bool
	force               bool
	listClusters        bool
	listContexts        bool
	report              bool
	exportContexts      string
	mergeConfigs        []string
	destination         string
	dryRun              bool
	probeTimeoutSeconds int
	output              string
	mergeStrategy       string
	doctor              bool
	ui                  bool
	verbose             bool
}

func NewRootCommand() *cobra.Command {
	opts := &options{backup: true}
	cmd := &cobra.Command{
		Use:   "kubetidy",
		Short: "Clean and manage kubeconfig files",
		Long:  "KubeTidy cleans kubeconfig files by removing unreachable clusters and related users/contexts, and can also list, export, merge, and report on kubeconfig data.",
		Example: strings.TrimSpace(`
kubetidy --kubeconfig "$HOME/.kube/config" --listclusters
kubetidy --kubeconfig "$HOME/.kube/config" --dryrun --force --probe-timeout-seconds 8
kubetidy --kubeconfig "$HOME/.kube/config" --report --output json
kubetidy doctor --kubeconfig "$HOME/.kube/config" --output yaml
kubetidy completion powershell
kubetidy --exportcontexts "prod-a,prod-b" --destinationconfig "$HOME/.kube/filtered-config"
kubetidy --mergeconfigs config1.yaml --mergeconfigs config2.yaml --destinationconfig "$HOME/.kube/config" --merge-strategy keep-first`),
		SilenceUsage:  true,
		SilenceErrors: true,
		RunE: func(cmd *cobra.Command, args []string) error {
			outputMode := normalizeOutput(opts.output)
			if !opts.ui && outputMode == outputText {
				printBanner(cmd.OutOrStdout())
			}

			logger := func(format string, values ...any) {
				if opts.verbose {
					fmt.Fprintf(cmd.ErrOrStderr(), "VERBOSE: %s\n", fmt.Sprintf(format, values...))
				}
			}

			svc := kubeconfig.Service{Logf: logger}
			source, err := kubeconfig.ResolveSource(opts.kubeConfigPath)
			if err != nil {
				return err
			}
			strategy, err := kubeconfig.NormalizeMergeStrategy(opts.mergeStrategy)
			if err != nil {
				return err
			}

			switch {
			case len(opts.mergeConfigs) > 0:
				destination := opts.destination
				if destination == "" {
					destination = source.WritePath
				}
				result, err := svc.Merge(kubeconfig.MergeOptions{
					Paths:       opts.mergeConfigs,
					Destination: destination,
					DryRun:      opts.dryRun,
					Strategy:    strategy,
				})
				if err != nil {
					return err
				}
				return renderOutput(cmd.OutOrStdout(), outputMode, result)
			case strings.TrimSpace(opts.exportContexts) != "":
				destination := opts.destination
				if destination == "" {
					destination = kubeconfig.DefaultFilteredConfigPath()
				}
				result, err := svc.Export(kubeconfig.ExportOptions{
					SourcePath:      strings.Join(source.Paths, string(filepath.ListSeparator)),
					DestinationPath: destination,
					Contexts:        splitCSV(opts.exportContexts),
					MergeStrategy:   strategy,
				})
				if err != nil {
					return err
				}
				return renderOutput(cmd.OutOrStdout(), outputMode, result)
			case opts.listClusters:
				result, err := svc.ListClusters(source, strategy)
				if err != nil {
					return err
				}
				return renderOutput(cmd.OutOrStdout(), outputMode, result)
			case opts.listContexts:
				result, err := svc.ListContexts(source, strategy)
				if err != nil {
					return err
				}
				return renderOutput(cmd.OutOrStdout(), outputMode, result)
			case opts.report:
				result, err := svc.Report(source, strategy)
				if err != nil {
					return err
				}
				return renderOutput(cmd.OutOrStdout(), outputMode, result)
			case opts.doctor:
				result, err := svc.Doctor(source, strategy)
				if err != nil {
					return err
				}
				return renderOutput(cmd.OutOrStdout(), outputMode, result)
			default:
				result, err := svc.Cleanup(kubeconfig.CleanupOptions{
					Source:        source,
					ExclusionList: opts.exclusionList,
					Backup:        opts.backup,
					Force:         opts.force,
					DryRun:        opts.dryRun,
					ProbeTimeout:  time.Duration(opts.probeTimeoutSeconds) * time.Second,
					MergeStrategy: strategy,
				})
				if err != nil {
					return err
				}
				return renderOutput(cmd.OutOrStdout(), outputMode, result)
			}
		},
	}

	cmd.Version = buildVersion()
	cmd.Flags().StringVar(&opts.kubeConfigPath, "kubeconfig", "", "Path to your kubeconfig file. Supports multiple paths separated with the platform path separator.")
	cmd.Flags().StringSliceVar(&opts.exclusionList, "exclusionlist", nil, "Comma-separated list of clusters to exclude from cleanup.")
	cmd.Flags().BoolVar(&opts.backup, "backup", true, "Create a backup before cleanup.")
	cmd.Flags().BoolVar(&opts.force, "force", false, "Force cleanup even if no clusters are reachable.")
	cmd.Flags().BoolVar(&opts.listClusters, "listclusters", false, "Display a list of all clusters in the kubeconfig file.")
	cmd.Flags().BoolVar(&opts.listContexts, "listcontexts", false, "Display a list of all contexts in the kubeconfig file.")
	cmd.Flags().BoolVar(&opts.report, "report", false, "Show a kubeconfig report without modifying any files.")
	cmd.Flags().BoolVar(&opts.doctor, "doctor", false, "Run kubeconfig health checks without modifying any files.")
	cmd.Flags().StringVar(&opts.exportContexts, "exportcontexts", "", "Comma-separated list of contexts to export from the kubeconfig.")
	cmd.Flags().StringSliceVar(&opts.mergeConfigs, "mergeconfigs", nil, "Array of kubeconfig files to merge.")
	cmd.Flags().StringVar(&opts.destination, "destinationconfig", "", "Path to save the merged or exported kubeconfig file.")
	cmd.Flags().BoolVar(&opts.dryRun, "dryrun", false, "Simulate the cleanup process without making changes.")
	cmd.Flags().IntVar(&opts.probeTimeoutSeconds, "probe-timeout-seconds", 5, "Timeout in seconds for cluster reachability probes during cleanup.")
	cmd.Flags().StringVar(&opts.output, "output", string(outputText), "Output format: text, json, yaml.")
	cmd.Flags().StringVar(&opts.mergeStrategy, "merge-strategy", string(kubeconfig.MergeStrategyKeepFirst), "Merge strategy for duplicate names: keep-first, keep-last, fail-on-conflict.")
	cmd.Flags().BoolVar(&opts.ui, "ui", false, "Suppress the banner for UI integrations.")
	cmd.Flags().BoolVarP(&opts.verbose, "verbose", "v", false, "Enable verbose logging.")

	cmd.AddCommand(newDoctorCommand())
	cmd.AddCommand(newCompletionCommand())
	cmd.AddCommand(newVersionCommand())

	return cmd
}

func newDoctorCommand() *cobra.Command {
	opts := &options{}
	cmd := &cobra.Command{
		Use:   "doctor",
		Short: "Analyze kubeconfig health and highlight risky entries",
		RunE: func(cmd *cobra.Command, args []string) error {
			outputMode := normalizeOutput(opts.output)
			if !opts.ui && outputMode == outputText {
				printBanner(cmd.OutOrStdout())
			}

			logger := func(format string, values ...any) {
				if opts.verbose {
					fmt.Fprintf(cmd.ErrOrStderr(), "VERBOSE: %s\n", fmt.Sprintf(format, values...))
				}
			}

			source, err := kubeconfig.ResolveSource(opts.kubeConfigPath)
			if err != nil {
				return err
			}
			strategy, err := kubeconfig.NormalizeMergeStrategy(opts.mergeStrategy)
			if err != nil {
				return err
			}

			result, err := (kubeconfig.Service{Logf: logger}).Doctor(source, strategy)
			if err != nil {
				return err
			}
			return renderOutput(cmd.OutOrStdout(), outputMode, result)
		},
	}

	cmd.Flags().StringVar(&opts.kubeConfigPath, "kubeconfig", "", "Path to your kubeconfig file. Supports multiple paths separated with the platform path separator.")
	cmd.Flags().StringVar(&opts.output, "output", string(outputText), "Output format: text, json, yaml.")
	cmd.Flags().StringVar(&opts.mergeStrategy, "merge-strategy", string(kubeconfig.MergeStrategyKeepFirst), "Merge strategy for duplicate names: keep-first, keep-last, fail-on-conflict.")
	cmd.Flags().BoolVar(&opts.ui, "ui", false, "Suppress the banner for UI integrations.")
	cmd.Flags().BoolVarP(&opts.verbose, "verbose", "v", false, "Enable verbose logging.")
	return cmd
}

func newCompletionCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:       "completion [bash|zsh|fish|powershell]",
		Short:     "Generate shell completion scripts",
		ValidArgs: []string{"bash", "zsh", "fish", "powershell"},
		Args:      cobra.ExactValidArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			root := cmd.Root()
			switch args[0] {
			case "bash":
				return root.GenBashCompletion(cmd.OutOrStdout())
			case "zsh":
				return root.GenZshCompletion(cmd.OutOrStdout())
			case "fish":
				return root.GenFishCompletion(cmd.OutOrStdout(), true)
			case "powershell":
				return root.GenPowerShellCompletionWithDesc(cmd.OutOrStdout())
			default:
				return fmt.Errorf("unsupported shell %q", args[0])
			}
		},
	}
	return cmd
}

func newVersionCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "version",
		Short: "Show version, commit, and build date information",
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Fprintln(cmd.OutOrStdout(), buildVersion())
		},
	}
}

func splitCSV(value string) []string {
	parts := strings.Split(value, ",")
	out := make([]string, 0, len(parts))
	for _, part := range parts {
		part = strings.TrimSpace(part)
		if part != "" {
			out = append(out, part)
		}
	}
	return out
}

func printBanner(out io.Writer) {
	const brightCyan = "\033[1;38;5;45m"
	const reset = "\033[0m"

	fmt.Fprintln(out)
	fmt.Fprintln(out, brightCyan+" ██╗  ██╗██╗   ██╗██████╗ ███████╗████████╗██╗██████╗ ██╗   ██╗"+reset)
	fmt.Fprintln(out, brightCyan+" ██║ ██╔╝██║   ██║██╔══██╗██╔════╝╚══██╔══╝██║██╔══██╗╚██╗ ██╔╝"+reset)
	fmt.Fprintln(out, brightCyan+" █████╔╝ ██║   ██║██████╔╝█████╗     ██║   ██║██║  ██║ ╚████╔╝ "+reset)
	fmt.Fprintln(out, brightCyan+" ██╔═██╗ ██║   ██║██╔══██╗██╔══╝     ██║   ██║██║  ██║  ╚██╔╝  "+reset)
	fmt.Fprintln(out, brightCyan+" ██║  ██╗╚██████╔╝██████╔╝███████╗   ██║   ██║██████╔╝   ██║   "+reset)
	fmt.Fprintln(out, brightCyan+" ╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚══════╝   ╚═╝   ╚═╝╚═════╝    ╚═╝   "+reset)
	fmt.Fprintln(out)
}
