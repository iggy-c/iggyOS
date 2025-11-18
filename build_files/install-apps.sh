#!/usr/bin/bash
set -euo pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

log "Starting Amy OS build process"

#
# ENABLE REPOS
#
log "Adding external repos"

# Docker CE repo
dnf5 -y config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo

# Brave browser repo
dnf5 -y config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc

# Microsoft VSCode repo
dnf5 -y config-manager --add-repo https://packages.microsoft.com/yumrepos/vscode
rpm --import https://packages.microsoft.com/keys/microsoft.asc

# Cloudflare WARP repo
dnf5 -y config-manager --add-repo https://pkg.cloudflareclient.com/cloudflare-warp.repo


#
# PACKAGE GROUPS
#
declare -A RPM_PACKAGES=(
  ["fedora"]="\
    fuse-btfs \
    fuse-devel \
    fuse3-devel \
    fzf \
    gnome-disk-utility \
    gparted \
    gwenview \
    isoimagewriter \
    kcalc \
    kgpg \
    ksystemlog \
    micro \
    nmap \
    qemu-kvm \
    util-linux \
    virt-manager \
    virt-viewer \
    wireshark"

  ["terra"]="\
    firacode-nerd-fonts \
    firemono-nerd-fonts \
    starship"

  # Split rpmfusion repos into separate keys
  ["rpmfusion-free"]="\
    audacious \
    audacious-plugins-freeworld \
    audacity-freeworld"

  ["rpmfusion-free-updates"]="\
    audacious \
    audacious-plugins-freeworld \
    audacity-freeworld"

  ["rpmfusion-nonfree"]="\
    audacious \
    audacious-plugins-freeworld \
    audacity-freeworld"

  ["rpmfusion-nonfree-updates"]="\
    audacious \
    audacious-plugins-freeworld \
    audacity-freeworld"

  ["docker-ce"]="\
    containerd.io \
    docker-buildx-plugin \
    docker-ce \
    docker-ce-cli \
    docker-compose-plugin"

  ["brave-browser"]="brave-browser"
  ["cloudflare-warp"]="cloudflare-warp"
  ["vscode"]="code"
)

#
# INSTALL PACKAGES
#
log "Installing RPM packages"

mkdir -p /var/opt

for repo in "${!RPM_PACKAGES[@]}"; do
  read -ra pkg_array <<<"${RPM_PACKAGES[$repo]}"

  if [[ $repo == copr:* ]]; then
    log "Installing from COPR: $repo"
    copr_repo=${repo#copr:}
    dnf5 -y copr enable "$copr_repo"
    dnf5 -y install "${pkg_array[@]}"
    dnf5 -y copr disable "$copr_repo"

  elif [[ $repo == "fedora" ]]; then
    # base repo: no flags needed
    log "Installing from base Fedora repo"
    dnf5 -y install "${pkg_array[@]}"

  else
    # regular repo: use --repo=
    log "Installing from repo: $repo"
    dnf5 -y install --repo="$repo" "${pkg_array[@]}"
  fi
done


#
# SYSTEMD PRESETS (instead of systemctl enable)
#
log "Configuring systemd presets"

mkdir -p /usr/lib/systemd/system-preset
cat >/usr/lib/systemd/system-preset/99-amyos.preset <<EOF
enable docker.socket
enable libvirtd.service
EOF


log "Build process completed"
