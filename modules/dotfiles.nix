{ pkgs, ... }:

let
  dotfilesCmd = pkgs.writeShellScriptBin "dotfiles" ''
    set -euo pipefail

    exec git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" "$@"
  '';

  dotfilesInitCmd = pkgs.writeShellScriptBin "dotfiles-init" ''
    set -euo pipefail

    if [ "$#" -ne 1 ]; then
      echo "usage: dotfiles-init <repo-url>" >&2
      exit 1
    fi

    repo_url="$1"
    git_dir="$HOME/.dotfiles"
    work_tree="$HOME"

    if [ -e "$git_dir" ]; then
      echo "$git_dir already exists" >&2
      exit 1
    fi

    git clone --bare "$repo_url" "$git_dir"
    git --git-dir="$git_dir" --work-tree="$work_tree" checkout
    git --git-dir="$git_dir" --work-tree="$work_tree" config --local status.showUntrackedFiles no
  '';
in
{
  programs.fish = {
    enable = true;
    shellAliases = {
      config = "dotfiles";
    };
  };

  environment.systemPackages = [
    dotfilesCmd
    dotfilesInitCmd
  ];
}
