# my personal dotfiles

Managed with GNU Stow.

## Directory Structure

Common configuration files are in the root directory (vim/nvim/tmux/fzf, etc.).

- For Arch Linux specific configurations (i3/polybar, etc.), see the `archlinux` folder.
- For Macos specific configurations (yabai/sketchybar, etc.), see the `macos` folder.

## Usage

```bash
cd ~
git clone git@github.com:gogongxt/dotfiles.git
cd dotfiles
stow -t ~ */
```

This symlinks all packages to your home directory. You can also stow individual packages:

```bash
stow zsh  # only link the zsh package
```

## Troubleshooting

If a config file already exists, stow will report an error. Backup and remove the original file, then run `stow -t ~ */` again.

**Important:** If the target directory already exists, stow will symlink the files _inside_ that directory rather than the directory itself. This is usually not what you want.

**Recommendation:** Remove the existing directory before stowing to ensure the whole folder is symlinked.

For more details, see `man stow` or the [GNU Stow manual](https://www.gnu.org/software/stow/manual/).
