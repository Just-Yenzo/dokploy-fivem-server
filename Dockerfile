FROM ich777/debian-baseimage

LABEL org.opencontainers.image.authors="contact@justyenzo.be"
LABEL org.opencontainers.image.source="https://github.com/Just-Yenzo/docker-fivem-server"

# --- Installation de base ---
RUN apt-get update && \
    apt-get -y install --no-install-recommends xz-utils unzip screen && \
    rm -rf /var/lib/apt/lists/*

# --- Installation de GoTTY pour console web ---
RUN wget -O /tmp/gotty.tar.gz https://github.com/yudai/gotty/releases/download/v1.0.1/gotty_linux_amd64.tar.gz && \
    tar -C /usr/bin/ -xvf /tmp/gotty.tar.gz && \
    rm -rf /tmp/gotty.tar.gz

# --- Variables d’environnement ---
ENV SERVER_DIR="/serverdata"
ENV USER="fivem"

# --- Création de l’utilisateur et des dossiers ---
RUN mkdir -p $SERVER_DIR && \
    useradd -d $SERVER_DIR -s /bin/bash $USER && \
    chown -R $USER $SERVER_DIR && \
    ulimit -n 2048

# --- Scripts ---
ADD /scripts/ /opt/scripts/
RUN chmod -R 770 /opt/scripts/

# --- Volume persistant ---
VOLUME ["/serverdata"]

# --- Dossier de travail (racine du serveur) ---
WORKDIR /serverdata

# --- Lancement du serveur ---
ENTRYPOINT ["/opt/scripts/start.sh"]
