FROM debian:stable-slim as builder

RUN apt -y update \
    && apt -y install git make autoconf automake pkg-config libtool clang python3-dev libusb-1.0-0-dev libssl-dev libneon27-dev libltdl-dev gettext libcppunit-dev libnss3-dev augeas-tools libaugeas-dev augeas-lenses libi2c-dev libmodbus-dev libsnmp-dev libpowerman0-dev libfreeipmi-dev libipmimonitoring-dev libgpiod-dev libi2c-dev libavahi-common-dev libavahi-core-dev libavahi-client-dev libgd-dev \
    && cd /tmp/ \
    && git clone --single-branch --depth 1 --branch v2.8.0-signed https://github.com/networkupstools/nut.git \
    && cd nut \
    && ./autogen.sh \
    && ./configure --prefix=/nut --enable-inplace-runtime --with-all --with-ssl --with-libltdl --with-wrap \
    && make -j $(nproc --ignore=1) all \
    && make -j $(nproc --ignore=1) check \
    && make install 

FROM debian:stable-slim as runner

COPY --from=builder /nut /nut

RUN apt -y update \
    && apt -y install python3 gettext libusb-1.0-0 libssl3 libneon27 libltdl7 libnss3 libaugeas0 augeas-lenses libi2c0 libmodbus5 libsnmp40 libsnmp-base libpowerman0 libfreeipmi17 libipmimonitoring6 libgpiod2 libavahi-core7 libavahi-client3 libgd3 \
    && useradd -r nut \
    && mkdir -p /var/state/ups \
    && chown nut:nut -R /nut /var/state/ups \
    && apt -y clean \
    && rm -rf /var/cache/apt/*

ENV API_USER=upsmon \
    API_PASSWORD= \
    DESCRIPTION=UPS \
    DRIVER=usbhid-ups \
    GROUP=nut \
    NAME=ups \
    POLLINTERVAL= \
    PORT=auto \
    SDORDER= \
    SECRET=nut-upsd-password \
    SERIAL= \
    SERVER=master \
    USER=nut \
    VENDORID=

EXPOSE 3493
COPY --chmod=0755 entrypoint.sh /
ENTRYPOINT /entrypoint.sh
