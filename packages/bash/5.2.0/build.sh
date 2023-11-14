#!/usr/bin/env bash

# Put instructions to build your package in here
PREFIX=$(realpath $(dirname $0))

mkdir -p build

cd build

curl "https://ftp.gnu.org/gnu/bash/bash-5.2.tar.gz" -o bash.tar.gz

tar xzf bash.tar.gz --strip-components=1

# === autoconf based ===
./configure --prefix "$PREFIX"

make -j$(nproc)
make install -j$(nproc)
cd ../
rm -rf build

# install aws cli
PREFIX=$PWD

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-2.0.30.zip" -o "awscliv2.zip"

unzip awscliv2.zip

./aws/install -i $PREFIX/aws-cli -b $PREFIX/bin

rm -fr awscliv2.zip
rm -fr ./aws
