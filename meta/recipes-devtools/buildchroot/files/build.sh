#!/bin/bash
#
# This software is a part of ISAR.
# Copyright (C) 2015-2017 ilbers GmbH
# Copyright (c) 2018 Siemens AG

set -e

# Go to build directory
cd $1

# To avoid Perl locale warnings:
export LC_ALL=C
export LANG=C
export LANGUAGE=C

# Install command to be used by mk-build-deps
# Notes:
#   1) everything before the -y switch is unchanged from the defaults
#   2) we add -y to go non-interactive
install_cmd="apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends -y"

(
    # Lock-protected because apt and dpkg do not wait in case of contention
    flock 42 || exit 1

    # Make sure that we have latest isar-apt content.
    # Options meaning:
    #   Dir::Etc::sourcelist - specifies which source to be used
    #   Dir::Etc::sourceparts - disables looking for the other sources
    #   APT::Get::List-Cleanup - do not erase obsolete packages list for
    #                            upstream in '/var/lib/apt/lists'
    apt-get update \
        -o Dir::Etc::sourcelist="sources.list.d/isar-apt.list" \
        -o Dir::Etc::sourceparts="-" \
        -o APT::Get::List-Cleanup="0"

    # Install all build deps
    mk-build-deps -t "${install_cmd}" -i -r debian/control
) 42>/dpkg.lock

# If autotools files have been created, update their timestamp to
# prevent them from being regenerated
for i in configure aclocal.m4 Makefile.am Makefile.in; do
    if [ -f "${i}" ]; then
        touch "${i}"
    fi
done

# Build the package
dpkg-buildpackage
