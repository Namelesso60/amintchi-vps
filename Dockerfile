# 1. Base Ubuntu 22.04
FROM ubuntu:22.04

# Évite les questions d'installation
ENV DEBIAN_FRONTEND=noninteractive

# 2. Installation Système + Chrome + Outils
# Installation groupée pour optimiser le temps de build
RUN apt-get update && apt-get install -y \
    xfce4 \
    xfce4-terminal \
    xfce4-goodies \
    dbus-x11 \
    xvfb \
    x11vnc \
    novnc \
    python3-websockify \
    python3-numpy \
    sudo \
    curl \
    wget \
    git \
    htop \
    nano \
    fonts-liberation \
    fonts-ubuntu \
    fonts-noto-color-emoji \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 3. Installation Google Chrome
RUN wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    apt-get update && apt-get install -y ./google-chrome-stable_current_amd64.deb && \
    rm google-chrome-stable_current_amd64.deb

# 4. Création utilisateur "amintchi"
RUN useradd -m -u 1000 amintchi
RUN echo "amintchi ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 5. Configuration Dossiers
RUN mkdir -p /var/run/dbus && chmod 777 /var/run/dbus
RUN mkdir -p /tmp/.X11-unix && chmod 1777 /tmp/.X11-unix
RUN chown -R amintchi:amintchi /home/amintchi

# 6. CRÉATION DU SCRIPT (AVEC FIX RÉSEAU 0.0.0.0)
# La modification est dans la dernière ligne echo 'websockify...'
# On ajoute "0.0.0.0:" devant le port pour forcer l'écoute publique.
RUN echo '#!/bin/bash' > /home/amintchi/start.sh && \
    echo 'rm -rf /tmp/.X11-unix/X0' >> /home/amintchi/start.sh && \
    echo 'echo "--- Demarrage Xvfb ---"' >> /home/amintchi/start.sh && \
    echo 'Xvfb :0 -screen 0 1920x1080x24 &' >> /home/amintchi/start.sh && \
    echo 'sleep 2' >> /home/amintchi/start.sh && \
    echo 'echo "--- Demarrage XFCE ---"' >> /home/amintchi/start.sh && \
    echo 'dbus-launch startxfce4 &' >> /home/amintchi/start.sh && \
    echo 'sleep 2' >> /home/amintchi/start.sh && \
    echo 'echo "--- Demarrage VNC ---"' >> /home/amintchi/start.sh && \
    echo 'x11vnc -display :0 -nopw -forever -shared -bg' >> /home/amintchi/start.sh && \
    echo 'echo "--- Demarrage NoVNC (Ecoute sur 0.0.0.0) ---"' >> /home/amintchi/start.sh && \
    echo 'websockify --web=/usr/share/novnc/ 0.0.0.0:${PORT:-10000} localhost:5900' >> /home/amintchi/start.sh && \
    chmod +x /home/amintchi/start.sh && \
    chown amintchi:amintchi /home/amintchi/start.sh

# 7. Démarrage
USER amintchi
WORKDIR /home/amintchi
ENV HOME=/home/amintchi
ENV DISPLAY=:0
ENV RESOLUTION=1920x1080

CMD ["/bin/bash", "/home/amintchi/start.sh"]

