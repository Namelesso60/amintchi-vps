# 1. Base Debian
FROM debian:bullseye

ENV DEBIAN_FRONTEND=noninteractive

# 2. Architecture 32 bits (Obligatoire pour Wine)
RUN dpkg --add-architecture i386

# 3. Installation des paquets (Wine, Bureau, Outils)
# J'ai ajouté 'procps' pour htop/kill et nettoyé la liste
RUN apt-get update && apt-get install -y \
    wine \
    wine32 \
    wine64 \
    qemu-system-x86 \
    xz-utils \
    dbus-x11 \
    curl \
    wget \
    git \
    firefox-esr \
    gnome-system-monitor \
    mate-system-monitor \
    xfce4 \
    xfce4-terminal \
    tightvncserver \
    python3 \
    python3-numpy \
    python3-websockify \
    fonts-wqy-zenhei \
    sudo \
    procps \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 4. Installation manuelle de NoVNC (Comme tu le voulais)
WORKDIR /opt
RUN wget -q https://github.com/novnc/noVNC/archive/refs/tags/v1.2.0.tar.gz && \
    tar -xvf v1.2.0.tar.gz && \
    mv noVNC-1.2.0 novnc && \
    rm v1.2.0.tar.gz && \
    git clone https://github.com/novnc/websockify /opt/novnc/utils/websockify

# 5. Création de l'utilisateur "amintchi" (Pour éviter les bugs Firefox/Wine en root)
RUN useradd -m -u 1000 amintchi
RUN echo "amintchi ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 6. Configuration VNC pour l'utilisateur
USER amintchi
ENV HOME=/home/amintchi
RUN mkdir -p $HOME/.vnc
# Mot de passe VNC (admin123@a)
RUN echo 'admin123@a' | vncpasswd -f > $HOME/.vnc/passwd
RUN chmod 600 $HOME/.vnc/passwd
# Script de démarrage XFCE pour VNC
RUN echo '#!/bin/sh' > $HOME/.vnc/xstartup && \
    echo 'unset SESSION_MANAGER' >> $HOME/.vnc/xstartup && \
    echo 'unset DBUS_SESSION_BUS_ADDRESS' >> $HOME/.vnc/xstartup && \
    echo 'startxfce4 &' >> $HOME/.vnc/xstartup && \
    chmod +x $HOME/.vnc/xstartup

# 7. Création du script de démarrage compatible Render
# Note : On utilise 'websockify' directement car launch.sh est parfois capricieux sur les ports
RUN echo '#!/bin/bash' > $HOME/luo.sh && \
    echo 'rm -rf /tmp/.X11-unix/X*' >> $HOME/luo.sh && \
    echo 'echo "--- Demarrage VNC (Port 5901) ---"' >> $HOME/luo.sh && \
    echo 'vncserver :1 -geometry 1280x720 -depth 24' >> $HOME/luo.sh && \
    echo 'sleep 3' >> $HOME/luo.sh && \
    echo 'echo "--- Demarrage NoVNC sur le port ${PORT:-10000} ---"' >> $HOME/luo.sh && \
    echo '/opt/novnc/utils/websockify/run --web=/opt/novnc 0.0.0.0:${PORT:-10000} localhost:5901' >> $HOME/luo.sh && \
    chmod +x $HOME/luo.sh

# 8. Lancement
CMD ["/home/amintchi/luo.sh"]

