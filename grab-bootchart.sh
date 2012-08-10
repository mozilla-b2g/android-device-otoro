#!/bin/sh
#
# this script is used to retrieve the bootchart log generated
# by init when compiled with INIT_BOOTCHART=true.
# Copied from system/core/init/grab-bootchart.sh, with an additional filter

TMPDIR=/tmp/android-bootchart
rm -rf $TMPDIR
mkdir -p $TMPDIR

LOGROOT=/data/bootchart
TARBALL=bootchart.tgz

FILES="header proc_stat.log proc_ps.log proc_diskstats.log kernel_pacct"

for f in $FILES; do
    adb pull $LOGROOT/$f $TMPDIR/$f 2>&1 > /dev/null
done
mv $TMPDIR/header $TMPDIR/header.orig
sed '/system.uname/s/([^)]*) *//;/system.kernel.options/s/androidboot.serialno=[^ ]* *//' $TMPDIR/header.orig > $TMPDIR/header
rm -f $TMPDIR/header.orig
(cd $TMPDIR && tar -czf $TARBALL $FILES)
cp -f $TMPDIR/$TARBALL ./$TARBALL
echo "look at $TARBALL"
