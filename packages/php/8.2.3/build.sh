#!/bin/bash

PREFIX=$(realpath $(dirname $0))

mkdir -p build/php
cd build

curl "https://www.php.net/distributions/php-8.2.3.tar.gz" -o php.tar.gz
tar xzf php.tar.gz --strip-components=1 -C php

cd php


./configure --prefix "$PREFIX" --with-openssl --enable-mbstring

make -j$(nproc)
make install -j$(nproc)

cd ../../
rm -rf build

# install aws sdk through .zip
curl -s -o aws.zip https://docs.aws.amazon.com/aws-sdk-php/v3/download/aws.zip
unzip aws.zip
