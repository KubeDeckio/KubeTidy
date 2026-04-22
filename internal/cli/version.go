package cli

import "strings"

var (
	version = "dev"
	commit  = "unknown"
	date    = "unknown"
)

func buildVersion() string {
	parts := []string{"version=" + version}
	if strings.TrimSpace(commit) != "" && commit != "unknown" {
		parts = append(parts, "commit="+commit)
	}
	if strings.TrimSpace(date) != "" && date != "unknown" {
		parts = append(parts, "date="+date)
	}
	return strings.Join(parts, " ")
}
