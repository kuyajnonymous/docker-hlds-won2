FROM i386/debian:8-slim

# Force Debian 8 installation!
RUN echo "deb http://archive.debian.org/debian jessie main contrib non-free" > /etc/apt/sources.list

# 1) Install dependencies
RUN apt-get update && apt-get upgrade -y && apt-get install -y wget libc6 libstdc++6 --force-yes

# 2) Create user
RUN groupadd -r hlds
RUN useradd --no-log-init --system --create-home --home-dir /server --gid hlds  hlds
USER hlds

# 3) Install HLDS 3.1.1.1 and 3.1.1.e
# RUN wget -q -O -  https://archive.org/download/hlds_l_3111_full_202503/hlds_l_3111_full.bin | \
#   tail -c+8338 | head -c121907818 | \
#   tar -xzf - -C /server

# COPY install/hlds_l_3111e_update.tar.gz /server 
# RUN tar -xzf /server/hlds_l_3111e_update.tar.gz -C /server
# RUN rm /server/hlds_l_3111e_update.tar.gz

# Download and extract valve.tar.gz into /server/hlds_l/
RUN wget -q -O /tmp/valve.tar.gz https://archive.org/download/hlds_l_3111_full_202503/valve.tar.gz && \
    mkdir -p /server/hlds_l/ && \
    tar -xzf /tmp/valve.tar.gz -C /server/hlds_l/ && \
    rm /tmp/valve.tar.gz

WORKDIR /server/hlds_l/

#Install WON2Fixes and modified HLDS_RUN
USER root

COPY patch/* ./
COPY config/valve ./valve
RUN chmod +x hlds*

# Then, remove mod folders
RUN rm -rf ./tfc
RUN rm -rf ./dmc
RUN rm -rf ./ricochet
RUN rm -rf ./cstrike

USER hlds

ENV TERM xterm

ENTRYPOINT ["./hlds_run"]

CMD ["-game valve", "+map crossfire", "+maxplayers 16"]
