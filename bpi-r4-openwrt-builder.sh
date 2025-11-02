#!/bin/bash

#*****************************************************************************
#
# Build environment - Ubuntu 64-bit Desktop 25.04
#
# sudo apt update
# sudo apt install build-essential clang flex bison g++ gawk \
# gcc-multilib g++-multilib gettext git libncurses-dev libssl-dev \
# python3-setuptools rsync swig unzip zlib1g-dev file wget \
# libtraceevent-dev systemtap-sdt-dev libslang2-dev
#
#*****************************************************************************

rm -rf openwrt
rm -rf mtk-openwrt-feeds

git clone --branch openwrt-24.10 https://github.com/openwrt/openwrt.git openwrt || true
cd openwrt; git checkout 859ff7a978aea150588e7e21a1333884ab85739f; cd -;		#OpenWrt v24.10.4: revert to branch defaults


git clone  https://git01.mediatek.com/openwrt/feeds/mtk-openwrt-feeds || true
cd mtk-openwrt-feeds; git checkout 60187042c718f690452b43190d15b381333f22ce; cd -;	#[openwrt-24.10][mt7988][dts][Add WiFi HW reset GPIO support in PCIE device tree]

echo "601870" > mtk-openwrt-feeds/autobuild/unified/feed_revision

\cp -r my_files/w-rules mtk-openwrt-feeds/autobuild/unified/filogic/rules

### remove mtk strongswan uci support patch
rm -rf mtk-openwrt-feeds/24.10/patches-feeds/108-strongswan-add-uci-support.patch 

### wireless-regdb modification - this remove all regdb wireless countries restrictions
rm -rf openwrt/package/firmware/wireless-regdb/patches/*.*
rm -rf mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/files/package/firmware/wireless-regdb/patches/*.*
\cp -r my_files/500-tx_power.patch mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/files/package/firmware/wireless-regdb/patches
\cp -r my_files/regdb.Makefile openwrt/package/firmware/wireless-regdb/Makefile

### tx_power patch - required for BE14 boards with defective eeprom flash
\cp -r my_files/99999_tx_power_check.patch mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/files/package/kernel/mt76/patches/

### required & thermal zone 
\cp -r my_files/1007-wozi-arch-arm64-dts-mt7988a-add-thermal-zone.patch mtk-openwrt-feeds/24.10/patches-base/

sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/defconfig
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/autobuild_5.4_mac80211_release/mt7988_wifi7_mac80211_mlo/.config
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/autobuild_5.4_mac80211_release/mt7986_mac80211/.config

cd openwrt
bash ../mtk-openwrt-feeds/autobuild/unified/autobuild.sh filogic-mac80211-mt7988_rfb-mt7996 log_file=make

exit 0

########### After successful end of build #############

## IMPORTANT NOTE !!!!!
## Do not change Target Profile from Multiple devices to other  !!!
## Do not remove MediaTek MT7988A rfb and MediaTek MT7988D rfb from Target Devices !!! 

#################

###### Then you can add all required additional feeds/packages ######### 

# dts overlay for disable m2 sim1 pcie mode
#\cp -r ../my_files/mt7988a-bananapi-bpi-r4-disable-pcie2.dtso target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek/mt7988a-bananapi-bpi-r4-disable-pcie2.dtso

./scripts/feeds update -a
./scripts/feeds install -a



####### And finally configure whatever you want ##########

\cp -r ../configs/fb-modem.config .config
make menuconfig
make V=s -j$(nproc)


