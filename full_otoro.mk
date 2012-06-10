$(call inherit-product, device/qcom/common/common.mk)
PRODUCT_COPY_FILES := \
  device/qcom/otoro/Fts-touchscreen.idc:system/usr/idc/Fts-touchscreen.idc \
  device/qcom/otoro/atmel-touchscreen.idc:system/usr/idc/atmel-touchscreen.idc \
  external/wpa_supplicant_8/wpa_supplicant/wpa_supplicant.conf:system/etc/wifi/wpa_supplicant.conf

$(call inherit-product-if-exists, vendor/qcom/otoro/otoro-vendor-blobs.mk)
$(call inherit-product-if-exists, vendor/qcom/common/vendor-blobs.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full.mk)

PRODUCT_PROPERTY_OVERRIDES += \
  rild.libpath=/system/lib/libril-qc-1.so \
  rild.libargs=-d/dev/smd0

# Discard inherited values and use our own instead.
PRODUCT_NAME := full_otoro
PRODUCT_DEVICE := otoro
PRODUCT_BRAND := toro
PRODUCT_MANUFACTURER := toro
PRODUCT_MODEL := otoro1

