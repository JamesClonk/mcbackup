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
RUN useradd -u 2000 -mU -s /bin/bash mcbackup && \
  mkdir /home/mcbackup/app && \
  chown mcbackup:mcbackup /home/mcbackup/app

# add backup script
WORKDIR /home/mcbackup/app
COPY backup.sh ./

RUN chmod u+x /home/mcbackup/app/backup.sh
RUN chown -R mcbackup:mcbackup /home/mcbackup/app
USER mcbackup

CMD ["/home/mcbackup/app/backup.sh"]
