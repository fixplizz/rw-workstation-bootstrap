# New Laptop Runbook

This is the intended fresh Windows 11 + WSL Ubuntu bootstrap flow.

## Manual Prerequisites

Install these once on the Windows machine:

- WSL Ubuntu

Inside the fresh WSL Ubuntu 24 shell, install the minimum needed to clone:

```bash
sudo apt-get update
sudo apt-get install -y git curl
```

## Clone

Clone the public bootstrap repo and the private secrets repo into the same
parent directory:

```bash
mkdir -p ~/projects/rw-omniroute
cd ~/projects/rw-omniroute
git clone git@github.com:fixplizz/rw-workstation-bootstrap.git
git clone git@github.com:fixplizz/rw-workstation-secrets.git
```

## Secrets

Preferred path: unlock the encrypted vault from the private repo. The password is
entered locally and is not stored in git:

```bash
cd ~/projects/rw-omniroute/rw-workstation-secrets
bash scripts/vault-unlock.sh
```

Fallback path: create real ignored env files from the examples in the private
repo:

```bash
cd ~/projects/rw-omniroute/rw-workstation-secrets
cp env/omniroute/.env.example env/omniroute/.env
cp env/providers/nvidia.env.example env/providers/nvidia.env
chmod 600 env/omniroute/.env env/providers/nvidia.env
```

Then fill in your private values locally. Do not commit real keys.

After editing ignored env files on your main machine, refresh the encrypted
vault:

```bash
cd ~/projects/rw-omniroute/rw-workstation-secrets
bash scripts/vault-seal.sh
git add vault/workstation-secrets.tar.gz.enc vault/workstation-secrets.manifest
git commit -m "Update encrypted workstation vault"
git push
```

## Bootstrap

Run one setup command:

```bash
cd ~/projects/rw-omniroute/rw-workstation-bootstrap
bash scripts/setup-workstation.sh
```

Expected result:

- WSL gets the baseline packages, zsh, Oh My Zsh, useful plugins, and managed
  dotfiles.
- Windows gets Git, Docker Desktop, Edge WebView2 Runtime, and OpenCode Desktop
  through the PowerShell/winget bootstrap where available.
- OpenCode is installed in WSL.
- OpenCode config and agent rules are linked into the user config directory.
- OmniRoute is running in Docker on `http://localhost:20128`.
- OmniRoute state persists in Docker volume `rw-omniroute-data-live`.

## Work

Launch OpenCode through the repo wrapper so private provider env files are
loaded from `rw-workstation-secrets`:

```bash
cd ~/projects/rw-omniroute/rw-workstation-bootstrap
bash scripts/run-opencode.sh
```

OpenCode defaults to local OmniRoute at `http://localhost:20128/v1`. Configure
the NVIDIA provider/key in OmniRoute and keep matching local API token values in
the private secrets repo.

For the first end-to-end question through OmniRoute:

```bash
bash scripts/smoke-opencode.sh
```

## Verify

```bash
bash scripts/verify-workstation.sh --current
```

If the machine already has another OmniRoute container using port `20128`, run
the non-invasive sandbox test instead:

```bash
bash scripts/test-omniroute-sandbox.sh
```
