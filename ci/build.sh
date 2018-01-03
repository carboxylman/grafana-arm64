#!/bin/bash

set -x

usage() {
  base="$(basename "$0")"
  cat <<EOUSAGE
usage: $base [-r] <arch>
Install specific packages to build grafana for armv6, armv7, arm64 (armv8)
Use -r for release package
Available arch:
  $base armv6
  $base armv7
  $base arm64
EOUSAGE
}

install_phjs() {
  PHJSURL="https://github.com/fg2it/phantomjs-on-raspberry/releases/download/${PHJSV}"
  PHJS=/tmp/${ARM}/phantomjs
  mkdir -p /tmp/${ARM}
  curl -sSL ${PHJSURL}/phantomjs -o ${PHJS}
  chmod a+x ${PHJS}
}

armv6_install_cross(){
  cd /tmp
  git clone https://github.com/fg2it/cross-rpi1b.git
  CROSSPATH="/tmp/cross-rpi1b/arm-rpi-4.9.3-linux-gnueabihf/bin/"
  CC=${CROSSPATH}/arm-linux-gnueabihf-gcc
  CXX=${CROSSPATH}/arm-linux-gnueabihf-g++
  PARCH=armhf
}

armv7_install_cross() {
  echo "deb http://emdebian.org/tools/debian/ jessie main" > /etc/apt/sources.list.d/crosstools.list
  curl -sSL http://emdebian.org/tools/debian/emdebian-toolchain-archive.key | apt-key add -
  dpkg --add-architecture armhf
  apt-get update
  apt-get install -y crossbuild-essential-armhf
  CC=arm-linux-gnueabihf-gcc
  CXX=arm-linux-gnueabihf-g++
  PARCH=armhf
}

arm64_install_cross() {
  echo "deb http://emdebian.org/tools/debian/ jessie main" > /etc/apt/sources.list.d/crosstools.list
  curl -sSL http://emdebian.org/tools/debian/emdebian-toolchain-archive.key | apt-key add -
  dpkg --add-architecture arm64
  apt-get update
  apt-get install -y crossbuild-essential-arm64
  CC=aarch64-linux-gnu-gcc
  CXX=aarch64-linux-gnu-g++
  PARCH=arm64
}

build() {
  cd $GOPATH/src/github.com/grafana/grafana
  go run build.go                   \
     -pkg-arch=${PARCH}             \
     -goarch=${ARM}                 \
     -cgo-enabled=1                 \
     -cc=$CC                        \
     -cxx=$CXX                      \
     -phjs=${PHJS}                  \
     -includeBuildNumber=${includeBuildNumber} \
         build                      \
         pkg-deb
}


includeBuildNumber="true"
if [ "$1" == "-r" ]; then
  echo "Package for release"
  includeBuildNumber="false"
  shift
fi

if (( $# != 1 )); then
	usage >&2
	exit 1
fi

ARM="$1"

case "$ARM" in
  armv6)
    PHJSV="v2.1.1-wheezy-jessie-armv6"
    armv6_install_cross
    ;;
  armv7)
    PHJSV="v2.1.1-wheezy-jessie"
    armv7_install_cross
    ;;
  arm64|aarch64|armv8)
    PHJSV="v2.1.1-wheezy-jessie"
    ARM=arm64
    arm64_install_cross
    ;;
  *)
    echo >&2 'error: unknown arch:' "$ARM"
    usage >&2
    exit 1
    ;;
esac

install_phjs
build
