#!/bin/bash

set -ouex pipefail

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

# DNF5 Speedup
sed -i '/^\[main\]/a max_parallel_downloads=10' /etc/dnf/dnf.conf

# 1. Abilitazione del repository COPR ufficiale per DankMaterialShell (DMS)
echo "--- Abilitazione COPR per DMS ---"
dnf -y install dnf-plugins-core
dnf copr enable -y avengemedia/danklinux
dnf copr enable -y avengemedia/dms

# 2. Installazione dei pacchetti richiesti
echo "--- Installazione pacchetti di sistema ---"
# --- core di WAYLAND & XDG PORTALS ---
dnf install -y \
    wayland-utils \
    xdg-desktop-portal \
    xdg-desktop-portal-gnome \
    lxpolkit \
    xdg-utils \
    xorg-x11-server-Xwayland
# --- AUDIO & PIPEWIRE ---
dnf install -y \
    pipewire \
    pipewire-utils \
    pipewire-alsa \
    pipewire-jack-audio-connection-kit \
    pipewire-pulseaudio \
    wireplumber \
    pavucontrol
# --- GRAFICA (MESA & VULKAN) ---
dnf install -y \
    mesa-dri-drivers \
    mesa-vulkan-drivers \
    vulkan-loader \
    vulkan-tools \
    clinfo
# --- RETE, WI-FI & BLUETOOTH ---
dnf install -y \
    NetworkManager \
    NetworkManager-wifi \
    linux-firmware \
    iwlxxway-firmware \
    bluez \
    bluez-utils \
    blueman
# --- DESKTOP ENVIRONMENT (NIRI + DMS) ---
dnf install -y \
    niri \
    dms \
    quickshell \
    matugen \
    cliphist \
    danksearch \
    dgop \
    dankcalendar-git \
    ghostty \
    dms-greeter
# --- UTILITY AGGIUNTIVE E COMPATIBILITÀ ---
dnf install -y \
    alacritty \
    kitty \
    gnome-keyring \
    wl-clipboard
# --- PODMAN ---
dnf install -y \
    podman \
    podman-compose
# --- DOCKER ---
dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
dnf remove -y docker \
    docker-client \
    docker-client-latest \
    docker-common \
    docker-latest \
    docker-latest-logrotate \
    docker-logrotate \
    docker-engine
dnf install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

# 3. Abilitazione dei servizi di sistema essenziali
systemctl enable NetworkManager.service
systemctl enable bluetooth.service
systemctl enable podman.socket
systemctl enable docker

# 4. Configurazione Automatica di Niri per DMS via /etc/skel (Metodo Pseudo)
mkdir -p /etc/skel/.config/niri/dms
cp -rf /ctx/dot_config/niri/config.kdl /etc/skel/.config/niri/

# Generiamo il file dms.kdl inserendo l'avvio automatico e l'interfaccia
cat > /etc/skel/.config/niri/dms/dms.kdl << 'EOF'
spawn-at-startup "dms" "run"
EOF

# 5. Installazione e configurazione del Display Manager (greetd + dms-greeter)
mkdir -p /etc/greetd/
cat > /etc/greetd/config.toml << EOF
[terminal]
vt = 1

[default_session]
user = "greeter"
command = "dms-greeter --command niri"
EOF

# 6. Abilitazione di greetd disabilitando eventauli GDM/SDDM preesistenti
rm -f /etc/systemd/system/display-manager.service
ln -s /usr/lib/systemd/system/greetd.service /etc/systemd/system/display-manager.service
systemctl enable --force greetd.service
mkdir -p /etc/skel/.config/systemd/user/graphical-session.target.wants
ln -s /usr/lib/systemd/user/dms.service /etc/skel/.config/systemd/user/graphical-session.target.wants/

# 7. Pulizia della cache per ridurre il peso dell'immagine finale
dnf clean all
rm -rf /run/dnf /run/selinux-policy
rm -rf /var/lib/dnf
