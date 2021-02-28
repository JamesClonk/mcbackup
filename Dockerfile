FROM ubuntu:20.04

LABEL maintainer="JamesClonk <jamesclonk@jamesclonk.ch>"

# add additional packages
RUN apt-get -y update \
  && apt-get -y install unzip zlibc openssl zip curl wget ca-certificates netcat \
  && apt-get autoremove -y \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# install minio client CLI
RUN wget 'https://dl.minio.io/client/mc/release/linux-amd64/mc' \
  && mv mc /usr/local/bin/mc \
  && chmod 755 /usr/local/bin/mc

# install rcon CLI
RUN wget 'https://github.com/itzg/rcon-cli/releases/download/1.4.8/rcon-cli_1.4.8_linux_amd64.tar.gz' \
  && tar -C /usr/local/bin -xzf rcon-cli_1.4.8_linux_amd64.tar.gz \
  && rm -f rcon-cli_1.4.8_linux_amd64.tar.gz \
  && chmod 755 /usr/local/bin/rcon-cli

# create backup user
RUN useradd -u 1000 -mU -s /bin/bash minecraft && \
  mkdir /home/minecraft/app && \
  chown minecraft:2000 /home/minecraft/app

# add backup script
WORKDIR /home/minecraft/app
COPY backup.sh ./

RUN chmod u+x /home/minecraft/app/backup.sh
RUN chown -R minecraft:2000 /home/minecraft/app
USER minecraft

CMD ["/home/minecraft/app/backup.sh"]
