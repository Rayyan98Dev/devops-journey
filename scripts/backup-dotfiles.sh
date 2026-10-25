#!/usr/bin/env bash
# backup-dotfiles.sh - copies your desktop setup into ~/dotfiles (a Git repo) and commits it.
# Safe to run any time: it only READS your configs and writes inside ~/dotfiles.
# It never copies ~/.ssh or ~/.config/gh (those hold keys and tokens).
set -euo pipefail

dest="$HOME/dotfiles"
mkdir -p "$dest/config" "$dest/system"
cd "$dest"
[ -d .git ] || git init -q -b main

# Keep secrets and junk out of the repo even if they sneak into a folder
if [ ! -f .gitignore ]; then
  cat > .gitignore <<'EOF'
.env
.env.*
*.pem
*.key
id_rsa*
id_ed25519*
*.tfvars
.cache/
EOF
fi

# 1) Your configs
for name in sway waybar foot kitty dunst rofi swaylock gtk-3.0 gtk-4.0 theme xkb user-tmpfiles.d; do
  src="$HOME/.config/$name"
  if [ -d "$src" ]; then
    rm -rf "${dest:?}/config/$name"
    cp -a "$src" "$dest/config/$name"
  fi
done

# Single files from your home folder (the prompt lives in .bashrc)
mkdir -p "$dest/config/home"
for f in "$HOME/.bashrc"; do
  [ -r "$f" ] && cp "$f" "$dest/config/home/$(basename "$f" | sed 's/^\.//')"
done

# 2) System files we changed (copies for reference; restoring these needs sudo)
for f in /etc/sddm.conf.d/zz-theme.conf /etc/udev/rules.d/60-i2c.rules \
         /etc/modules-load.d/i2c-dev.conf /etc/pam.d/sddm /etc/pam.d/swaylock \
         /etc/default/grub \
         /usr/share/sddm/themes/breeze/theme.conf.user; do
  if [ -r "$f" ]; then
    cp "$f" "$dest/system/$(printf '%s' "$f" | tr '/' '_')"
  fi
done
authselect current > "$dest/system/authselect-current.txt" 2>/dev/null || true

# 3) Packages you installed on purpose
dnf repoquery --userinstalled --qf '%{name}\n' 2>/dev/null | sort -u > "$dest/packages.txt" || true

# 4) Look for obvious secrets before anything gets committed
hits="$(grep -rniE 'password|passwd|secret|token|api[_-]?key|BEGIN [A-Z ]*PRIVATE KEY' config system 2>/dev/null | grep -v 'password-auth' || true)"
if [ -n "$hits" ]; then
  echo "These lines look like secrets:"
  echo "$hits"
  if [ "${FORCE:-0}" != "1" ]; then
    echo
    echo "Nothing was committed. Fix or remove those lines, then run this again."
    echo "If they are harmless (say, a comment), run:  FORCE=1 bash $0"
    exit 2
  fi
else
  echo "No obvious secrets found."
fi

git add -A
git commit -q -m "Backup $(date +%F)" || echo "No changes since the last backup."
echo
git status -sb | head -5
