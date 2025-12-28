# 1. Base Ubuntu
FROM ubuntu:22.04

# Mode silencieux
ENV DEBIAN_FRONTEND=noninteractive

# 2. Installation ULTRA-LÉGÈRE (Fluxbox au lieu de XFCE)
# fluxbox : Bureau minimaliste (consomme presque 0 RAM)
# rox-filer : Pour avoir des icônes (optionnel mais pratique)
RUN apt-get update && apt-get install -y \
    fluxbox \
    xterm \
    xvfb \
    x11vnc \
    novnc \
    python3-websockify \
    python3-numpy \
    sudo \
    curl \
    wget \
    fonts-liberation \
    fonts-ubuntu \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 3. Installation Chrome
RUN wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    apt-get update && apt-get install -y ./google-chrome-stable_current_amd64.deb && \
    rm google-chrome-stable_current_amd64.deb

# 4. Utilisateur
RUN useradd -m -u 1000 amintchi
RUN echo "amintchi ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 5. Dossiers
RUN mkdir -p /tmp/.X11-unix && chmod 1777 /tmp/.X11-unix
RUN chown -R amintchi:amintchi /home/amintchi

# 6. SCRIPT DE DÉMARRAGE (Optimisé Fluxbox)
RUN echo '#!/bin/bash' > /home/amintchi/start.sh && \
    echo 'rm -rf /tmp/.X11-unix/X0' >> /home/amintchi/start.sh && \
    echo 'echo "--- 1. Xvfb (Ecran) ---"' >> /home/amintchi/start.sh && \
    echo 'Xvfb :0 -screen 0 1024x768x16 &' >> /home/amintchi/start.sh && \
    echo 'sleep 2' >> /home/amintchi/start.sh && \
    echo 'echo "--- 2. Fluxbox (Bureau) ---"' >> /home/amintchi/start.sh && \
    echo 'fluxbox &' >> /home/amintchi/start.sh && \
    echo 'sleep 1' >> /home/amintchi/start.sh && \
    echo 'echo "--- 3. VNC (Serveur) ---"' >> /home/amintchi/start.sh && \
    echo 'x11vnc -display :0 -nopw -forever -shared -bg' >> /home/amintchi/start.sh && \
    echo 'echo "--- 4. NoVNC (Web) ---"' >> /home/amintchi/start.sh && \
    echo 'websockify --web=/usr/share/novnc/ 0.0.0.0:${PORT:-10000} localhost:5900' >> /home/amintchi/start.sh && \
    chmod +x /home/amintchi/start.sh && \
    chown amintchi:amintchi /home/amintchi/start.sh

# 7. Lancement
USER amintchi
WORKDIR /home/amintchi
ENV HOME=/home/amintchi
ENV DISPLAY=:0

CMD ["/bin/bash", "/home/amintchi/start.sh"]

