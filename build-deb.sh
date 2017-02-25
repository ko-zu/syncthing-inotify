#!/bin/bash
set -euo pipefail

mntner="Lode Hoste <zillode@zillode.be>"
date=$(TZ=utc date +"%a, %d %b %Y %H:%M:%S %Z")
version=$(git describe --tags --always | sed 's/^v//')
ldflags="-w -X main.Version=$version"

build() { # os arch
	# Convert Debian format arch name to Go format
	arch="$2"
	if [[ $arch == "armhf" || $arch == "armel" ]]; then arch="arm"; fi
	if [[ $arch == "i386" ]]; then arch="386"; fi

	mkdir -p deb/usr/bin
	GOOS="$1" GOARCH="$arch" go build -v -i -ldflags "$ldflags" -o deb/usr/bin/syncthing-inotify
}

debianDir() { # arch
	arch="$1"

	rm -rf deb
	mkdir -p deb/DEBIAN

	cp debian/compat deb/DEBIAN/compat
	cat debian/control \
		| sed "s/{{arch}}/$arch/" \
		| sed "s/{{mntner}}/$mntner/" \
		| sed "s/{{version}}/$version/" \
		> deb/DEBIAN/control
	cat debian/changelog \
		| sed "s/{{date}}/$date/" \
		| sed "s/{{mntner}}/$mntner/" \
		| sed "s/{{version}}/$version/" \
		> deb/DEBIAN/changelog

	mkdir -p deb/lib/systemd
	mkdir -p deb/usr/lib/systemd
	cp -r etc/linux-systemd/system deb/lib/systemd
	cp -r etc/linux-systemd/user deb/usr/lib/systemd
}

# For each supported architecture (in Debian format), compile and pack into
# .deb archive.
for arch in amd64 i386 arm64 armhf armel ; do
	debianDir "$arch"
	build linux "$arch"
	dpkg-deb -b deb .
done
