#!/usr/bin/env bash
sudo pacman -Sy --needed  --noconfirm  archlinux-keyring 
sudo pacman -Syu --needed --noconfirm base-devel \
          bc \
          bison \
          ccache \
          clang \
          cpio \
          cmake \
          flex \
          git \
          libelf \
          lld \
          llvm \
          ninja \
          openssl \
          python3 
set -eo pipefail

# Function to show an informational message
function msg() {
    echo -e "\e[1;32m$@\e[0m"
}

# Don't touch repo if running on CI
[ -z "$GH_RUN_ID" ] && repo_flag="--shallow-clone" || repo_flag="--no-update"

# Build LLVM
msg "Building LLVM..."
./build-llvm.py \
	--vendor-string "Ghost " \
	--targets ARM AArch64 X86  \
	-s \
	--lto thin -i ./install

# Build binutils
msg "Building binutils..."
./build-binutils.py --targets arm aarch64 x86_64 -i ./install

# Remove unused products
msg "Removing unused products..."
rm -fr install/include
rm -f install/lib/*.a install/lib/*.la

# Strip remaining products
msg "Stripping remaining products..."
for f in $(find install -type f -exec file {} \; | grep 'not stripped' | awk '{print $1}'); do
	strip ${f: : -1}
done

# Set executable rpaths so setting LD_LIBRARY_PATH isn't necessary
msg "Setting library load paths for portability..."
for bin in $(find install -mindepth 2 -maxdepth 3 -type f -exec file {} \; | grep 'ELF .* interpreter' | awk '{print $1}'); do
	# Remove last character from file output (':')
	bin="${bin: : -1}"

	echo "$bin"
	patchelf --set-rpath '$ORIGIN/../lib' "$bin"
done
#hhhh   
