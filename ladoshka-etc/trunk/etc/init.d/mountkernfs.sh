#! /bin/sh
### BEGIN INIT INFO
# Provides:          mountkernfs
# Required-Start:
# Required-Stop:
# Should-Start:      glibc
# Default-Start:     S
# Default-Stop:
# Short-Description: Mount kernel virtual file systems.
# Description:       Mount initial set of virtual filesystems the kernel
#                    provides and that are required by everything.
### END INIT INFO

PATH=/lib/init:/sbin:/bin
. /lib/init/vars.sh

. /lib/lsb/init-functions
. /lib/init/mount-functions.sh

[ -f /etc/default/tmpfs ] && . /etc/default/tmpfs

do_start () {
	#
	# Get some writable area available before the root is checked
	# and remounted.
	#
	RW_OPT=
	[ "${RW_SIZE:=$TMPFS_SIZE}" ] && RW_OPT=",size=$RW_SIZE"
	domount tmpfs "" /lib/init/rw tmpfs -omode=0755,nosuid$RW_OPT
	touch /lib/init/rw/.ramfs

	# Make pidfile omit directory for sendsigs
	mkdir /lib/init/rw/sendsigs.omit.d/

	#
	# Mount proc filesystem on /proc
	#
	domount proc "" /proc proc -onodev,noexec,nosuid

	#
	# Mount sysfs on /sys
	#
	# Only mount sysfs if it is supported (kernel >= 2.6)
	if grep -E -qs "sysfs\$" /proc/filesystems
	then
		domount sysfs "" /sys sysfs -onodev,noexec,nosuid
	fi

	# Mount /var/run and /var/lock as tmpfs if enabled
	if [ yes = "$RAMRUN" ] ; then
		RUN_OPT=
		[ "${RUN_SIZE:=$TMPFS_SIZE}" ] && RUN_OPT=",size=$RUN_SIZE"
		domount tmpfs "" /var/run varrun -omode=0755,nosuid$RUN_OPT
		touch /var/run/.ramfs
	fi
	if [ yes = "$RAMLOCK" ] ; then
		LOCK_OPT=
		[ "${LOCK_SIZE:=$TMPFS_SIZE}" ] && LOCK_OPT=",size=$LOCK_SIZE"
		domount tmpfs "" /var/lock varlock -omode=1777,nodev,noexec,nosuid$LOCK_OPT
		touch /var/lock/.ramfs
	fi
        if [ yes = "$RAMLOG" ] ; then
                LOG_OPT=
                [ "${LOG_SIZE:=$TMPFS_SIZE}" ] && LOG_OPT=",size=$LOG_SIZE"
                domount tmpfs "" /var/log varlog -omode=1777,nodev,noexec,nosuid$LOG_OPT
                touch /var/log/.ramfs
        fi
        if [ yes = "$RAMTMP" ] ; then
                TMP_OPT=
                [ "${TMP_SIZE:=$TMPFS_SIZE}" ] && TMP_OPT=",size=$TMP_SIZE"
                domount tmpfs "" /tmp roottmp -omode=1777,nodev,noexec,nosuid$TMP_OPT
                touch /tmp/.ramfs
        fi


	[ ! -f /var/mem ] && mkdir -p /var/mem

	domount tmpfs "" /var/mem varmem -omode=1777,nodev,noexec,nosuid,size=64M

	tomem="/etc/network/run /var/lib/alsa /var/lib/dhcp3 /var/lib/initscripts /var/lib/urandom"

	for dir in $tomem; do
		mkdir -p /var/mem/$dir
	done

	tomem="/etc/mtab"

        for file in $tomem; do
                touch /var/mem/$file
        done


}

case "$1" in
  "")
	echo "Warning: mountkernfs should be called with the 'start' argument." >&2
	do_start
	;;
  start)
	do_start
	;;
  restart|reload|force-reload)
	echo "Error: argument '$1' not supported" >&2
	exit 3
	;;
  stop)
	# No-op
	;;
  *)
	echo "Usage: mountkernfs [start|stop]" >&2
	exit 3
	;;
esac

