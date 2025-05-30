export PATH="$HOME/zyc-clang/bin:$PATH"
export LD_LIBRARY_PATH="$HOME/zyc-clang/lib"
SECONDS=0
ZIPNAME="rsuntk_Ratibor-$(date '+%Y%m%d-%H%M').zip"

[ $USE_PERSONAL_DEFCONFIG = "true" ] && DEFCONFIG="rsuntk-X01BD_defconfig" || DEFCONFIG="asus/X01BD_defconfig"

if test -z "$(git rev-parse --show-cdup 2>/dev/null)" &&
   head=$(git rev-parse --verify HEAD 2>/dev/null); then
	ZIPNAME="${ZIPNAME::-4}-$(echo $head | cut -c1-8).zip"
fi

if ! [ -d "$HOME/zyc-clang" ]; then
echo "ZyC Clang not found! Cloning..."
wget -q https://github.com/ZyCromerZ/Clang/releases/download/21.0.0git-20250314-release/Clang-21.0.0git-20250314.tar.gz -O "ZyC-Clang.tar.gz"
mkdir ~/zyc-clang
tar -xf ZyC-Clang.tar.gz -C ~/zyc-clang
rm -rf ZyC-Clang.tar.gz
fi

USER="rsuntk"
HOSTNAME="nobody"

export BUILD_USERNAME=$USER
export BUILD_HOSTNAME=$HOSTNAME
export KBUILD_BUILD_USER=$USER
export KBUILD_BUILD_HOST=$HOSTNAME

export CROSS_COMPILE_ARM32=arm-linux-gnueabi-
export CROSS_COMPILE_COMPAT=$CROSS_COMPILE_ARM32

BUILD_FLAGS="
O=out
ARCH=arm64
CC=clang
LD=ld.lld
AR=llvm-ar
AS=llvm-as
NM=llvm-nm
OBJCOPY=llvm-objcopy
OBJDUMP=llvm-objdump
STRIP=llvm-strip
CROSS_COMPILE=aarch64-linux-gnu-
CROSS_COMPILE_ARM32=arm-linux-gnueabi-
CROSS_COMPILE_COMPAT=$CROSS_COMPILE_ARM32
CLANG_TRIPLE=aarch64-linux-gnu-
"

if [[ $1 = "-r" || $1 = "--regen" ]]; then
mkdir out
make $(echo $BUILD_FLAGS) $DEFCONFIG
cp out/.config arch/arm64/configs/$DEFCONFIG
rm -rf out
echo -e "\nRegened defconfig succesfully!"
exit
fi

if [[ $1 = "-c" || $1 = "--clean" ]]; then
echo -e "\nClean build!"
rm -rf out
fi

mkdir -p out
make $(echo $BUILD_FLAGS) $DEFCONFIG -j$(nproc --all)

echo -e "\nStarting compilation...\n"
make -j$(nproc --all) $(echo $BUILD_FLAGS) Image.gz-dtb

if [ -f "out/arch/arm64/boot/Image.gz-dtb" ]; then
echo -e "\nKernel compiled succesfully! Zipping up...\n"
git clone -q https://github.com/rsuntk/AnyKernel3 --single-branch
cp out/arch/arm64/boot/Image.gz-dtb AnyKernel3
cd AnyKernel3
sed -i "s/BLOCK=.*/BLOCK=\/dev\/block\/bootdevice\/by-name\/boot;/" "anykernel.sh"
zip -r9 "../$ZIPNAME" * -x '*.git*' README.md *placeholder
cd ..
if [ "$DO_CLEAN" = "true" ]; then 
rm -rf AnyKernel3 out/arch/arm64/boot
fi
echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
echo "Zip: $ZIPNAME"
else
echo -e "\nCompilation failed!"
fi
