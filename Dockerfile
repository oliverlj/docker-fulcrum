ARG MAKEFLAGS="-j ${WORKER_COUNT}"
ARG VERSION=v1.8.2

FROM debian:bullseye as builder

ARG MAKEFLAGS
ARG VERSION

WORKDIR /build

RUN apt update -y && \
    apt install -y openssl git build-essential pkg-config zlib1g-dev libbz2-dev libjemalloc-dev libzmq3-dev qtbase5-dev qt5-qmake

RUN git clone --branch $VERSION https://github.com/cculianu/Fulcrum .

# RUN cargo install --locked --path .
RUN qmake -makefile PREFIX=/usr Fulcrum.pro && \
    make $MAKEFLAGS install

FROM debian:bullseye-slim

RUN apt update && \
    apt install -y openssl libqt5network5 zlib1g libbz2-1.0 libjemalloc2 libzmq5 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN adduser --disabled-password --uid 1000 --home /data --gecos "" fulcrum
USER fulcrum
WORKDIR /data

#COPY --from=builder /usr/local/cargo/bin/electrs /bin/electrs
COPY --from=builder /build/Fulcrum /usr/bin/fulcrum

# Electrum RPC
EXPOSE 50001

# Prometheus monitoring
EXPOSE 4224

STOPSIGNAL SIGINT

ENTRYPOINT ["fulcrum"]