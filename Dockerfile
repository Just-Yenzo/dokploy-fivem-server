FROM ich777/debian-baseimage

LABEL org.opencontainers.image.authors="contact@justyenzo.be"
LABEL org.opencontainers.image.source="https://github.com/Just-Yenzo/docker-fivem-server"

RUN apt-get update && \
	apt-get -y install --no-install-recommends xz-utils unzip screen && \
	rm -rf /var/lib/apt/lists/*

RUN wget -O /tmp/gotty.tar.gz https://github.com/yudai/gotty/releases/download/v1.0.1/gotty_linux_amd64.tar.gz && \
	tar -C /usr/bin/ -xvf /tmp/gotty.tar.gz && \
	rm -rf /tmp/gotty.tar.gz

RUN mkdir $DATA_DIR && \
	mkdir $SERVER_DIR && \
	useradd -d $SERVER_DIR -s /bin/bash $USER && \
	chown -R $USER $DATA_DIR && \
	ulimit -n 2048

ADD /scripts/ /opt/scripts/
RUN chmod -R 770 /opt/scripts/

VOLUME ["/serverdata"]
#Server Start
ENTRYPOINT ["/opt/scripts/start.sh"]
