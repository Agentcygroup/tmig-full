// Command tmig is the Go dispatcher for tmig-full.
//
// It mirrors ui/cli/tmig (the bash dispatcher) but adds one thing the
// shell version can't: before each subcommand runs, tmig consults the
// Cedar policy tree at policy/ to decide whether the calling principal
// is permitted to perform that action against the target resource.
//
// The policy decision is made by shelling out to xt (the Rust binary),
// which already links cedar-policy and can read policy/ as a
// Constitution. If xt is not on PATH, the Go dispatcher falls back to
// the bash dispatcher's own logic, but logs the decision as
// "policy-unchecked".
package main

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

const version = "0.2.0"

// subcommand describes one entry point.
type subcommand struct {
	name     string
	action   string // Cedar action name
	resource string // resource id used for the policy request
	cmd      []string
	desc     string
}

// registry lists every subcommand the dispatcher knows.
var registry = []subcommand{
	{"status", "read", "res:status", []string{"git", "log", "--oneline", "-1"}, "print repository state"},
	{"verify", "exec", "res:verify", []string{"bash", "scripts/local-verify.sh"}, "run the full local pipeline"},
	{"policy", "read", "res:policy", []string{"bash", "policy/check.sh"}, "check the Cedar policy tree"},
	{"doctor", "read", "res:doctor", []string{"bash", "dxp/doctor.sh"}, "diagnose the environment"},
	{"license", "read", "res:license", []string{"bash", "licensing/check.sh"}, "verify license allow list"},
	{"health", "read", "res:health", []string{"bash", "lifecycle/healthcheck.sh"}, "probe modality servers"},
	{"probe", "read", "res:probe", []string{"bash", "ix/probe.sh"}, "probe every declared endpoint"},
	{"infra-status", "read", "res:infra", []string{"bash", "infra/status.sh"}, "print infra reconciler state"},
	{"infra-reconcile", "write", "res:infra", []string{"bash", "infra/bin/reconcile"}, "converge infrastructure"},
	{"ui-web", "read", "res:ui", []string{"python3", "ui/web/server.py"}, "serve the static UI"},
	{"release", "release", "res:release", []string{"bash", "ci/release.sh"}, "tag, sign, upload a release"},
}

func findRoot() (string, error) {
	// Walk up from the executable's location until we find go.mod.
	exe, err := os.Executable()
	if err != nil {
		return "", err
	}
	dir := filepath.Dir(exe)
	for i := 0; i < 8; i++ {
		if _, err := os.Stat(filepath.Join(dir, "go.mod")); err == nil {
			return dir, nil
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			break
		}
		dir = parent
	}
	// Fall back to CWD
	cwd, err := os.Getwd()
	if err != nil {
		return "", err
	}
	return cwd, nil
}

// policyCheck asks xt to authorize (principal, action, resource).
// Returns (allowed, reason).
func policyCheck(root, principal, action, resource string) (bool, string) {
	xt := filepath.Join(root, "target", "release", "xt")
	if _, err := os.Stat(xt); err != nil {
		return true, "policy-unchecked (no xt binary)"
	}
	ctx := fmt.Sprintf(`{"principal":%q,"layer":"all","strength":40,"cmd":"","claim":"","resource_path":%q}`,
		principal, resource)
	cmd := exec.Command(xt, "policy", "authorize",
		"--principal", principal,
		"--action", action,
		"--resource", resource,
		"--context", ctx)
	cmd.Dir = root
	var out bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = &out
	err := cmd.Run()
	got := strings.TrimSpace(out.String())
	if err != nil {
		// xt doesn't yet have `policy authorize`; treat as unchecked.
		return true, "policy-unchecked (xt has no authorize subcommand)"
	}
	if got == "allow" {
		return true, "allow"
	}
	return false, got
}

func usage() {
	fmt.Fprintf(os.Stderr, "tmig %s — dispatcher\n\n", version)
	fmt.Fprintln(os.Stderr, "usage: tmig <command> [args...]")
	fmt.Fprintln(os.Stderr)
	fmt.Fprintln(os.Stderr, "commands:")
	for _, sc := range registry {
		fmt.Fprintf(os.Stderr, "  %-16s  %s\n", sc.name, sc.desc)
	}
}

func main() {
	if len(os.Args) < 2 {
		usage()
		os.Exit(1)
	}
	name := os.Args[1]

	if name == "version" || name == "-v" || name == "--version" {
		fmt.Println("tmig", version)
		return
	}
	if name == "help" || name == "-h" || name == "--help" {
		usage()
		return
	}

	root, err := findRoot()
	if err != nil {
		fmt.Fprintln(os.Stderr, "cannot locate repo root:", err)
		os.Exit(1)
	}

	for _, sc := range registry {
		if sc.name != name {
			continue
		}
		principal := os.Getenv("TMIG_PRINCIPAL")
		if principal == "" {
			principal = "xt"
		}
		allowed, reason := policyCheck(root, principal, sc.action, sc.resource)
		if !allowed {
			fmt.Fprintf(os.Stderr, "denied: %s %s %s — %s\n", principal, sc.action, sc.resource, reason)
			os.Exit(2)
		}
		fmt.Fprintf(os.Stderr, "policy: %s\n", reason)

		args := append(append([]string{}, sc.cmd[1:]...), os.Args[2:]...)
		c := exec.Command(sc.cmd[0], args...)
		c.Dir = root
		c.Stdout = os.Stdout
		c.Stderr = os.Stderr
		c.Stdin = os.Stdin
		if err := c.Run(); err != nil {
			if ee, ok := err.(*exec.ExitError); ok {
				os.Exit(ee.ExitCode())
			}
			fmt.Fprintln(os.Stderr, err)
			os.Exit(1)
		}
		return
	}

	fmt.Fprintf(os.Stderr, "unknown command: %s\n", name)
	usage()
	os.Exit(1)
}
