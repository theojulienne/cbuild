#!/bin/sh

OS=`uname`
TARGET="unknown"

case "$OS" in
	"Darwin")
		TARGET="darwin"
		;;
	*)
		echo "Sorry, I don't understand the OS 'uname' returned: $OS"
		exit 1
		;;
esac

BIN=`dirname $0`/binaries/cbuild-$TARGET

if [ ! -e "$BIN" ]; then
	echo "Could not find pre-compiled cbuild '$BIN'"
	exit 1
fi

echo "Launching cbuild for host '$TARGET'"
$BIN $*