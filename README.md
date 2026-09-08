# nixos-config

## Framework developer tools

Framework installs devenv from `cachix/devenv` and Claude Code from the community
flake `sadjow/claude-code-nix`. Both follow upstream's default branch, with exact
revisions pinned in `flake.lock`. For devenv this includes development commits,
not just tagged releases.

Update only these tools, review the lockfile, then rebuild:

```sh
nix flake update devenv claude-code
git diff -- flake.lock
sudo nixos-rebuild switch --flake .#framework
```

Automatic system upgrades are disabled on Framework. Rebuilding without updating
the lockfile keeps the pinned tool versions.

The old `pkgs/claude-code.nix` and `scripts/update-claude-code.sh` are no longer used
by Framework. They are retained to preserve the pending work on those files.

Generated `.devenv/` and `.direnv/` directories are ignored at every depth. The
root and `machines/` ad-hoc `devenv.lock` files are also ignored because neither
directory defines a devenv project. If adding one, remove its specific ignore
rule and commit its lockfile. Keep the system `flake.lock` tracked.
