#!/bin/bash

# Copyright (C) 2010 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

DEVICE=otoro
COMMON=common
MANUFACTURER=qcom

if [[ -z "${ANDROIDFS_DIR}" && -d ../../../backup-${DEVICE}/system ]]; then
    ANDROIDFS_DIR=../../../backup-${DEVICE}
fi

if [[ -z "${ANDROIDFS_DIR}" ]]; then
    echo Pulling files from device
    DEVICE_BUILD_ID=`adb shell cat /system/build.prop | grep ro.build.display.id | sed -e 's/ro.build.display.id=//' | tr -d '\n\r'`
else
    echo Pulling files from ${ANDROIDFS_DIR}
    DEVICE_BUILD_ID=`cat ${ANDROIDFS_DIR}/system/build.prop | grep ro.build.display.id | sed -e 's/ro.build.display.id=//' | tr -d '\n\r'`
fi

case "$DEVICE_BUILD_ID" in
ICS*)
  FIRMWARE=ICS
  echo Found ICS firmware with build ID $DEVICE_BUILD_ID >&2
  ;;
*)
  FIRMWARE=GB
  echo Found GB firmware with build ID $DEVICE_BUILD_ID >&2
  ;;
esac

if [[ ! -d ../../../backup-${DEVICE}/system  && -z "${ANDROIDFS_DIR}" ]]; then
    echo Backing up system partition to backup-${DEVICE}
    mkdir -p ../../../backup-${DEVICE} &&
    adb pull /system ../../../backup-${DEVICE}/system
fi

BASE_PROPRIETARY_COMMON_DIR=vendor/$MANUFACTURER/$COMMON/proprietary
PROPRIETARY_DEVICE_DIR=../../../vendor/$MANUFACTURER/$DEVICE/proprietary
PROPRIETARY_COMMON_DIR=../../../$BASE_PROPRIETARY_COMMON_DIR

mkdir -p $PROPRIETARY_DEVICE_DIR

for NAME in audio hw wifi etc
do
    mkdir -p $PROPRIETARY_COMMON_DIR/$NAME
done


COMMON_BLOBS_LIST=../../../vendor/$MANUFACTURER/$COMMON/vendor-blobs.mk

(cat << EOF) | sed s/__COMMON__/$COMMON/g | sed s/__MANUFACTURER__/$MANUFACTURER/g > $COMMON_BLOBS_LIST
# Copyright (C) 2010 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Prebuilt libraries that are needed to build open-source libraries
PRODUCT_COPY_FILES := device/sample/etc/apns-full-conf.xml:system/etc/apns-conf.xml

# All the blobs
PRODUCT_COPY_FILES += \\
EOF

# copy_file
# pull file from the device and adds the file to the list of blobs
#
# $1 = src name
# $2 = dst name
# $3 = directory path on device
# $4 = directory name in $PROPRIETARY_COMMON_DIR
copy_file()
{
    echo Pulling \"$1\"
    if [[ -z "${ANDROIDFS_DIR}" ]]; then
        adb pull /$3/$1 $PROPRIETARY_COMMON_DIR/$4/$2
    else
           # Hint: Uncomment the next line to populate a fresh ANDROIDFS_DIR
           #       (TODO: Make this a command-line option or something.)
           # adb pull /$3/$1 ${ANDROIDFS_DIR}/$3/$1
        cp ${ANDROIDFS_DIR}/$3/$1 $PROPRIETARY_COMMON_DIR/$4/$2
    fi

    if [[ -f $PROPRIETARY_COMMON_DIR/$4/$2 ]]; then
        echo   $BASE_PROPRIETARY_COMMON_DIR/$4/$2:$3/$2 \\ >> $COMMON_BLOBS_LIST
    else
        echo Failed to pull $1. Giving up.
        exit -1
    fi
}

# copy_files
# pulls a list of files from the device and adds the files to the list of blobs
#
# $1 = list of files
# $2 = directory path on device
# $3 = directory name in $PROPRIETARY_COMMON_DIR
copy_files()
{
    for NAME in $1
    do
        copy_file "$NAME" "$NAME" "$2" "$3"
    done
}

# copy_local_files
# puts files in this directory on the list of blobs to install
#
# $1 = list of files
# $2 = directory path on device
# $3 = local directory path
copy_local_files()
{
    for NAME in $1
    do
        echo Adding \"$NAME\"
        echo device/$MANUFACTURER/$DEVICE/$3/$NAME:$2/$NAME \\ >> $COMMON_BLOBS_LIST
    done
}

COMMON_LIBS="
	libauth.so
	libcm.so
	libdiag.so
	libdivxdrmdecrypt.so
	libdsi_netctrl.so
	libdsm.so
	libdss.so
	libdsutils.so
	libgsdi_exp.so
	libgstk_exp.so
	libidl.so
	libmmgsdilib.so
	libmm-adspsvc.so
	libnetmgr.so
	libnv.so
	libOmxAacDec.so
	libOmxH264Dec.so
	libOmxMp3Dec.so
	libOmxVp8Dec.so
	liboncrpc.so
	libpbmlib.so
	libqdp.so
	libqmi.so
	libqmiservices.so
	libqueue.so
	libril-qc-1.so
	libril-qc-qmi-1.so
	libril-qcril-hook-oem.so
	libSimCardAuth.so
	libwms.so
	libwmsts.so
	"

if [ "$FIRMWARE" = ICS ]; then
COMMON_LIBS="$COMMON_LIBS
	libcamera_client.so
	libcommondefs.so
	libgenlock.so
	libgemini.so
	libgps.utils.so
	libril.so
	libmmjpeg.so
	libmmipl.so
	liboemcamera.so
	libloc_adapter.so
	libloc_api-rpc-qc.so
	libloc_eng.so
	libqdi.so
	librpc.so
	"
fi

copy_files "$COMMON_LIBS" "system/lib" ""

COMMON_BINS="
	ATFWD-daemon
	akmd8962
	bridgemgrd
	fm_qsoc_patches
	fmconfig
	hci_qcomm_init
	netmgrd
	port-bridge
	proximity.init
	qmiproxy
	qmuxd
	"
if [ "$FIRMWARE" = ICS ]; then
COMMON_BINS="$COMMON_BINS
	rild
	radish
	"
else
COMMON_BINS="$COMMON_BINS
	amploader
	dhcpcd
	netd
	vold
	"
fi

copy_files "$COMMON_BINS" "system/bin" ""

COMMON_HW="
	sensors.default.so
	"
if [ "$FIRMWARE" = ICS ]; then
COMMON_HW="$COMMON_HW
	camera.msm7627a.so
	gps.default.so
	"
fi

copy_files "$COMMON_HW" "system/lib/hw" "hw"

if [ "$FIRMWARE" = ICS ]; then
COMMON_WIFI="
	ath6kl_sdio.ko
	cfg80211.ko
	"
else
COMMON_WIFI="
	ar6000.ko
	kineto_gan.ko
	"
fi

copy_files "$COMMON_WIFI" "system/wifi" "wifi"

if [ "$FIRMWARE" = ICS ]; then
COMMON_ATH6K="
	athtcmd_ram.bin
	bdata.bin
	fw-3.bin
	nullTestFlow.bin
	utf.bin
	"
copy_files "$COMMON_ATH6K" "system/etc/firmware/ath6k/AR6003/hw2.1.1" "wifi"
else
COMMON_ATH6K="
	athtcmd_ram.bin
	athwlan.bin
	athwlan_mobile.bin
	athwlan_router.bin
	athwlan_tablet.bin
	bdata.SD31.bin
	data.patch.hw3_0.bin
	device.bin
	otp.bin
	"
copy_files "$COMMON_ATH6K" "system/wifi/ath6k/AR6003/hw2.1.1" "wifi"
fi

COMMON_ETC="init.qcom.bt.sh gps.conf"
copy_files "$COMMON_ETC" "system/etc" "etc"

COMMON_AUDIO="
	"
#copy_files "$COMMON_AUDIO" "system/lib" "audio"

if [ ! -f "../../../Adreno200-AU_LINUX_ANDROID_ICS_CHOCO_CS.04.00.03.06.001.zip" ]; then
	echo Adreno driver not found. Please download the ARMv7 adreno driver from
	echo https://developer.qualcomm.com/mobile-development/mobile-technologies/gaming-graphics-optimization-adreno/tools-and-resources
	echo and put it in the top level B2G directory
	exit -1
fi

unzip -o -d ../../../vendor/$MANUFACTURER/$DEVICE ../../../Adreno200-AU_LINUX_ANDROID_ICS_CHOCO_CS.04.00.03.06.001.zip
(cat << EOF) | sed s/__DEVICE__/$DEVICE/g | sed s/__MANUFACTURER__/$MANUFACTURER/g > ../../../vendor/$MANUFACTURER/$DEVICE/$DEVICE-vendor-blobs.mk
# Copyright (C) 2010 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

LOCAL_PATH := vendor/$MANUFACTURER/$DEVICE

PRODUCT_COPY_FILES := \
    \$(LOCAL_PATH)/system/etc/firmware/yamato_pfp.fw:system/etc/firmware/yamato_pfp.fw \\
    \$(LOCAL_PATH)/system/etc/firmware/yamato_pm4.fw:system/etc/firmware/yamato_pm4.fw \\
    \$(LOCAL_PATH)/system/lib/libC2D2.so:system/lib/libC2D2.so \\
    \$(LOCAL_PATH)/system/lib/libsc-a2xx.so:system/lib/libsc-a2xx.so \\
    \$(LOCAL_PATH)/system/lib/libgsl.so:system/lib/libgsl.so \\
    \$(LOCAL_PATH)/system/lib/libOpenVG.so:system/lib/libOpenVG.so \\
    \$(LOCAL_PATH)/system/lib/egl/egl.cfg:system/lib/egl.cfg \\
    \$(LOCAL_PATH)/system/lib/egl/libGLESv1_CM_adreno200.so:system/lib/egl/libGLESv1_CM_adreno200.so \\
    \$(LOCAL_PATH)/system/lib/egl/libEGL_adreno200.so:system/lib/egl/libEGL_adreno200.so \\
    \$(LOCAL_PATH)/system/lib/egl/eglsubAndroid.so:system/lib/egl/eglsubAndroid.so \\
    \$(LOCAL_PATH)/system/lib/egl/libGLESv2_adreno200.so:system/lib/egl/libGLESv2_adreno200.so \\
    \$(LOCAL_PATH)/system/lib/egl/libq3dtools_adreno200.so:system/lib/egl/libq3dtools_adreno200.so \\
    \$(LOCAL_PATH)/system/lib/egl/libGLES_android.so:system/lib/egl/libGLES_android.so
EOF

BOOTIMG=boot-otoro.img
if [ -f ../../../${BOOTIMG} ]; then
    (cd ../../.. && ./build.sh unbootimg)
    . ../../../build/envsetup.sh
    HOST_OUT=$(get_build_var HOST_OUT_$(get_build_var HOST_BUILD_TYPE))
    KERNEL_DIR=../../../vendor/${MANUFACTURER}/${DEVICE}
    cp ../../../${BOOTIMG} ${KERNEL_DIR}
    ../../../${HOST_OUT}/bin/unbootimg ${KERNEL_DIR}/${BOOTIMG}
    mv ${KERNEL_DIR}/${BOOTIMG}-kernel ${KERNEL_DIR}/kernel
    rm -f ${KERNEL_DIR}/${BOOTIMG}-ramdisk.cpio.gz ${KERNEL_DIR}/${BOOTIMG}-second ${KERNEL_DIR}/${BOOTIMG}-mk ${KERNEL_DIR}/${BOOTIMG}
fi
