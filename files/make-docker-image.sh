#!/bin/bash -e
#
# Create a base CentOS Docker image.
#
# Adapted from [mkimage-yum](https://github.com/docker/docker/blob/master/contrib/mkimage-yum.sh)

mkdir -p /root/mkimage/gpg
wget -P /root/mkimage/gpg https://www.centos.org/keys/RPM-GPG-KEY-CentOS-5

name=centos5
yum_config=/root/mkimage/conf/yum.conf

#--------------------

target=$(mktemp -d /tmp/mkimage-yum.XXXXXX)

set -x

mkdir -m 755 "$target"/dev
mknod -m 600 "$target"/dev/console c 5 1
mknod -m 600 "$target"/dev/initctl p
mknod -m 666 "$target"/dev/full c 1 7
mknod -m 666 "$target"/dev/null c 1 3
mknod -m 666 "$target"/dev/ptmx c 5 2
mknod -m 666 "$target"/dev/random c 1 8
mknod -m 666 "$target"/dev/tty c 5 0
mknod -m 666 "$target"/dev/tty0 c 4 0
mknod -m 666 "$target"/dev/urandom c 1 9
mknod -m 666 "$target"/dev/zero c 1 5

rpm --root="$target" --rebuilddb
wget http://vault.centos.org/5.11/os/i386/CentOS/centos-release-5-11.el5.centos.i386.rpm
rpm --root="$target" --nodeps -ivh ./centos-release-*.rpm
rm -f ./centos-release*.rpm

yum -c "$yum_config" --installroot="$target" -y groupinstall Core
yum -c "$yum_config" --installroot="$target" -y install setarch
yum -c "$yum_config" --installroot="$target" -y clean all

cat > "$target"/etc/sysconfig/network <<EOF
NETWORKING=yes
HOSTNAME=localhost.localdomain
EOF

# effectively: febootstrap-minimize --keep-zoneinfo --keep-rpmdb
# --keep-services "$target".  Stolen from mkimage-rinse.sh
#  locales
rm -rf "$target"/usr/{{lib,share}/locale,{lib,lib64}/gconv,bin/localedef,sbin/build-locale-archive}
#  docs
rm -rf "$target"/usr/share/{man,doc,info,gnome/help}
#  cracklib
rm -rf "$target"/usr/share/cracklib
#  i18n
rm -rf "$target"/usr/share/i18n
#  sln
rm -rf "$target"/sbin/sln
#  ldconfig
rm -rf "$target"/etc/ld.so.cache
rm -rf "$target"/var/cache/ldconfig/*

version=
if [ -r "$target"/etc/redhat-release ]; then
    version="$(sed 's/^[^0-9\]*\([0-9.]\+\).*$/\1/' "$target"/etc/redhat-release)"
fi

if [ -z "$version" ]; then
    echo >&2 "warning: cannot autodetect OS version, using '$name' as tag"
    version=$name
fi

mkdir -p "$target"/etc/yum.repos.d
rm "$target"/var/lib/rpm/* "$target"/etc/yum.repos.d/*
cp /root/mkimage/gpg/* "$target"/etc/pki/rpm-gpg/
cp /root/mkimage/yum.repos.d/* "$target"/etc/yum.repos.d/
sed -i'' 's#gpgkey=.*#gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-5#g' "$target"/etc/yum.repos.d/*CentOS-5-Vault*.repo

tar --numeric-owner -c -C "$target" -zf /output/$name.tar.gz .
rm -rf "$target"

echo "Tarball successfully created!"
