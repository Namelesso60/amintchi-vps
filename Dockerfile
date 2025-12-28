# 1. Base Ubuntu légère
FROM ubuntu:22.04

# Évite les questions d'installation
ENV DEBIAN_FRONTEND=noninteractive

# 2. Installation minimale (Bureau + Chrome + Outils réseaux)
# J'ai retiré les outils lourds pour économiser la mémoire RAM
RUN apt-get update && apt-get install -y \
    xfce4 \
    xfce4-terminal \
    dbus-x11 \
    xvfb \
    x11vnc \
    novnc \
    python3-websockify \
    python3-numpy \
    sudo \
    curl \
    wget \
    htop \
    fonts-liberation \
    fonts-ubuntu \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 3. Installation Google Chrome
RUN wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    apt-get update && apt-get install -y ./google-chrome-stable_current_amd64.deb && \
    rm google-chrome-stable_current_amd64.deb

# 4. Création utilisateur
RUN useradd -m -u 1000 amintchi
RUN echo "amintchi ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 5. Configuration Dossiers
RUN mkdir -p /var/run/dbus && chmod 777 /var/run/dbus
RUN mkdir -p /tmp/.X11-unix && chmod 1777 /tmp/.X11-unix
RUN chown -R amintchi:amintchi /home/amintchi

# 6. SCRIPT DE DÉMARRAGE (Robuste)
RUN echo '#!/bin/bash' > /home/amintchi/start.sh && \
    echo 'rm -rf /tmp/.X11-unix/X0' >> /home/amintchi/start.sh && \
    echo 'Xvfb :0 -screen 0 1280x720x16 &' >> /home/amintchi/start.sh && \
    echo 'sleep 2' >> /home/amintchi/start.sh && \
    echo 'dbus-launch startxfce4 &' >> /home/amintchi/start.sh && \
    echo 'sleep 2' >> /home/amintchi/start.sh && \
    echo 'x11vnc -display :0 -nopw -forever -shared -bg' >> /home/amintchi/start.sh && \
    echo 'echo "Lancement NoVNC sur le port ${PORT:-10000}..."' >> /home/amintchi/start.sh && \
    echo 'websockify --web=/usr/share/novnc/ 0.0.0.0:${PORT:-10000} localhost:5900' >> /home/amintchi/start.sh && \
    chmod +x /home/amintchi/start.sh && \
    chown amintchi:amintchi /home/amintchi/start.sh

# 7. Lancement
USER amintchi
WORKDIR /home/amintchi
ENV HOME=/home/amintchi
ENV DISPLAY=:0
# Résolution un peu plus basse pour économiser la RAM
ENV RESOLUTION=1280x720

CMD ["/bin/bash", "/home/amintchi/start.sh"]

