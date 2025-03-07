FROM i386/debian

# Force Debian 8 installation (if needed)
# RUN echo "deb http://archive.debian.org/debian jessie main contrib non-free" > /etc/apt/sources.list && \
#     apt-get update -o Acquire::Check-Valid-Until=false

# Install dependencies
RUN apt-get update -o Acquire::Check-Valid-Until=false && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    wget curl libc6 libstdc++6 gcc make ca-certificates && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Create user
RUN groupadd -r hlds && useradd --no-log-init --system --create-home --home-dir /server --gid hlds hlds
USER hlds

# Download and extract HLDS
RUN curl -L -o /tmp/hlds_l_3109_full.tar.gz https://archive.org/download/hlds_l_3111_full/hlds_l_3109_full.tar.gz && \
    mkdir -p /server/hlds_l/ && \
    tar -xzf /tmp/hlds_l_3109_full.tar.gz -C /server/ && \
    rm /tmp/hlds_l_3109_full.tar.gz

WORKDIR /server/hlds_l/

# Install WON2Fixes and modified HLDS_RUN
USER root
# COPY patch/* ./
COPY config/valve ./valve
RUN chmod +x hlds*

# Remove unnecessary mod folders
RUN rm -rf ./tfc ./dmc ./ricochet ./cstrike

# 4) Create nowon.c file, compile, and link it
RUN echo 'int NET_IsReservedAdr(){return 1;}' > /server/hlds_l/nowon.c && \
    gcc -fPIC -c /server/hlds_l/nowon.c -o /server/hlds_l/nowon.o && \
    ld -shared -o /server/hlds_l/nowon.so /server/hlds_l/nowon.o && \
    rm -f /server/hlds_l/nowon.c /server/hlds_l/nowon.o

# 5) Modify hlds_run to include LD_PRELOAD
RUN sed -i '/^export /a export LD_PRELOAD="nowon.so"' /server/hlds_l/hlds_run

USER hlds

ENV TERM xterm

ENTRYPOINT ["./hlds_run"]
CMD ["-game", "valve", "+map", "crossfire", "+maxplayers", "16"]
