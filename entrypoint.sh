#! /bin/bash -e

if [ -d /run/secrets ] && [ -s /run/secrets/$SECRET ] && [ ! -z "${SECRET+x}" ]; then
  API_PASSWORD=$(cat /run/secrets/$SECRET)
fi

if [ ! -d /nut/etc ]; then
  mkdir -p /nut/etc
fi

if [ ! -e /nut/etc/.setup ]; then
  if [ -e /nut/etc/local/ups.conf ]; then
    cp /nut/etc/local/ups.conf /nut/etc/ups.conf
  else
    if [ -z "$SERIAL" ] && [ $DRIVER = usbhid-ups ] ; then
      echo "** This container may not work without setting for SERIAL **"
    fi
    cat <<EOF >>/nut/etc/ups.conf
[$NAME]
        driver = $DRIVER
        port = $PORT
        desc = "$DESCRIPTION"
EOF
    if [ ! -z "$SUBDRIVER" ]; then
      echo "        subdriver = \"$SUBDRIVER\"" >> /nut/etc/ups.conf
    fi
    if [ ! -z "$PROTOCOL" ]; then
      echo "        protocol = \"$PROTOCOL\"" >> /nut/etc/ups.conf
    fi
    if [ ! -z "$PRODUCT" ]; then
      echo "        product = \"$PRODUCT\"" >> /nut/etc/ups.conf
    fi
    if [ ! -z "$LANGID_FIX" ]; then
      echo "        langid_fix = \"$LANGID_FIX\"" >> /nut/etc/ups.conf
    fi
    if [ "$NORATING" = true ]; then
      echo "        norating" >> /nut/etc/ups.conf
    fi
    if [ "$NOVENDOR" = true ]; then
      echo "        novendor" >> /nut/etc/ups.conf
    fi
    if [ ! -z "$OVERRIDE_BATTERY_PACKS" ]; then
      echo "        override.battery.packs = \"$OVERRIDE_BATTERY_PACKS\"" >> /nut/etc/ups.conf
    fi
    if [ ! -z "$SERIAL" ]; then
      echo "        serial = \"$SERIAL\"" >> /nut/etc/ups.conf
    fi
    if [ ! -z "$POLLINTERVAL" ]; then
      echo "        pollinterval = $POLLINTERVAL" >> /nut/etc/ups.conf
    fi
    if [ ! -z "$VENDORID" ]; then
      echo "        vendorid = $VENDORID" >> /nut/etc/ups.conf
    fi
    if [ ! -z "$PRODUCTID" ]; then
      echo "        productid = \"$PRODUCTID\"" >> /nut/etc/ups.conf
    fi
    if [ ! -z "$SDORDER" ]; then
      echo "        sdorder = $SDORDER" >> /nut/etc/ups.conf
    fi
  fi
  if [ -e /nut/etc/local/upsd.conf ]; then
    cp /nut/etc/local/upsd.conf /nut/etc/upsd.conf
  else
    cat <<EOF >>/nut/etc/upsd.conf
LISTEN 0.0.0.0
EOF
  fi
  if [ -e /nut/etc/local/upsd.users ]; then
    cp /nut/etc/local/upsd.users /nut/etc/upsd.users
  else
    cat <<EOF >>/nut/etc/upsd.users
[$API_USER]
        password = $API_PASSWORD
        upsmon $SERVER
EOF
  fi
  if [ -e /nut/etc/local/upsmon.conf ]; then
    cp /nut/etc/local/upsmon.conf /nut/etc/upsmon.conf
  else
    cat <<EOF >>/nut/etc/upsmon.conf
MONITOR $NAME@localhost 1 $API_USER $API_PASSWORD $SERVER
RUN_AS_USER $USER
EOF
  fi
  touch /nut/etc/.setup
fi

chgrp $GROUP /nut/etc/*
chmod 640 /nut/etc/*
mkdir -p -m 2750 /dev/shm/nut
chown $USER:$GROUP /dev/shm/nut
if [ -f $PORT ]; then
  chown $USER:$GROUP $PORT
  chmod 0666 $PORT
fi
[ -e /var/run/nut ] || ln -s /dev/shm/nut /var/run
# Issue #15 - change pid warning message from "No such file" to "Ignoring"
echo 0 > /var/run/nut/upsd.pid && chown $USER:$GROUP /var/run/nut/upsd.pid
echo 0 > /var/run/upsmon.pid

/nut/sbin/upsdrvctl -u $USER start
/nut/sbin/upsd -u $USER
exec /nut/sbin/upsmon -D
