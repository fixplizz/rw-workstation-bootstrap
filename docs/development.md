# Development

## Repository Setup

Clone the Fixplizz repository, then configure upstream remotes:

```bash
git remote rename origin upstream-omabuntu
git remote add origin git@github.com:fixplizz/fixplizz-workstation.git
git remote add upstream-omakub https://github.com/basecamp/omakub.git
git remote -v
```

Expected remotes:

```text
origin              git@github.com:fixplizz/fixplizz-workstation.git
upstream-omabuntu   https://github.com/omakasui/omabuntu.git
upstream-omakub     https://github.com/basecamp/omakub.git
```

## Branches

```text
main      stable project line
develop   integration branch
stable    tested release branch
```

Use temporary sync branches for upstream work:

```text
sync/omabuntu-YYYY-MM-DD
```

## Local Validation

Run:

```bash
bash test/run.sh
```

The validation script runs `bash -n`, Bats tests, and optional ShellCheck/shfmt checks when those tools are installed.

Local Windows Git Bash validation is useful for syntax, unit tests, JSON checks, line endings, executable bits, and command metadata. It is not a substitute for Linux validation.

Before accepting PR 1, run:

```text
- GitHub Actions on the pushed feature branch;
- Linux smoke-test;
- Ubuntu 26.04 smoke-test when a real or containerized image is available;
- LF/executable-bit checks from the Git index;
- CLI smoke commands listed below.
```

Smoke commands:

```bash
bin/fixplizz help
bin/fixplizz version
bin/fixplizz commands
bin/fixplizz commands --check
bin/fixplizz commands --json
bin/fixplizz doctor
bin/fixplizz doctor --json
bin/fixplizz status
bin/fixplizz status --json
```

Record the successful GitHub Actions run URL in the PR description before merge.

## Environment Gate Tests

Production detection reads real system sources. Tests must use mock sources only with:

```bash
FIXPLIZZ_TEST_MODE=1
FIXPLIZZ_OS_RELEASE_FILE="$BATS_TEST_TMPDIR/os-release"
FIXPLIZZ_TEST_ARCH="x86_64"
FIXPLIZZ_TEST_DESKTOP="ubuntu:GNOME"
FIXPLIZZ_TEST_SESSION="wayland"
```

Without `FIXPLIZZ_TEST_MODE=1`, test override variables must be ignored.

## Tool Versions Used Locally

Record these in the final PR report:

```bash
bats --version
shellcheck --version
shfmt --version
jq --version
```
