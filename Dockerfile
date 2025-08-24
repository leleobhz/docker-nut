FROM docker.io/library/debian:stable-slim as builder

ARG branch

RUN echo "Building ${branch} branch" \
    && apt -y update \
    && apt -y install git make autoconf automake pkg-config libtool clang python3-dev libusb-1.0-0-dev libssl-dev libneon27-dev libltdl-dev gettext libcppunit-dev libnss3-dev augeas-tools libaugeas-dev augeas-lenses libi2c-dev libmodbus-dev libsnmp-dev libpowerman0-dev libfreeipmi-dev libipmimonitoring-dev libgpiod-dev libi2c-dev libavahi-common-dev libavahi-core-dev libavahi-client-dev libgd-dev \
    && ldconfig \
    && cd /tmp/ \
    && git clone --single-branch --depth 1 --branch ${branch} https://github.com/networkupstools/nut.git \
    && cd nut \
    && ./autogen.sh \
    && ./configure --prefix=/nut --enable-inplace-runtime --enable-docs-man-for-progs-built-only --with-all --with-ssl --with-libltdl --without-docs --disable-docs-changelog \
    && make -j $(nproc --ignore=1) all \
    && make -j $(nproc --ignore=1) check \
    && make install 

FROM docker.io/library/debian:stable-slim as runner

COPY --from=builder /nut /nut

RUN apt -y update \
    && apt -y install python3 gettext libusb-1.0-0 libssl3 libneon27 libltdl7 libnss3 libaugeas0 augeas-lenses libi2c0 libmodbus5 libsnmp40 libsnmp-base libpowerman0 libfreeipmi17 libipmimonitoring6 libgpiod3 libavahi-core7 libavahi-client3 libgd3 libnsl2 \
    && ldconfig \
    && useradd -r nut \
    && mkdir -p /var/state/ups \
    && chown nut:nut -R /nut /var/state/ups \
    && apt -y clean \
    && rm -rf /var/cache/apt/*

HEALTHCHECK CMD /nut/bin/upsc ups@localhost:3493 2>&1|grep -q stale && exit 1 || true

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
