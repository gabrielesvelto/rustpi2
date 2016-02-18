# Creates a docker image to cross compile Rust programs targetting a RPi2

FROM ubuntu:wily
MAINTAINER Fabrice Desré <fabrice@desre.org>

# Copy and extract the toolchain
ADD toolchain.tar.gz .

# Install dependencies
RUN apt-get update
RUN apt-get install -y libcurl3 gcc libstdc++-5-dev

RUN useradd -m -d /home/rustpi2 -p rustpi2 rustpi2

USER rustpi2
WORKDIR /home/rustpi2

ENV PATH=/opt/rustpi2/bin:/opt/rustpi2/x-tools/bin:$PATH
ENV LD_LIBRARY_PATH=/opt/rustpi2/lib:$LD_LIBRARY_PATH
ENV TARGET_CFLAGS="-I /opt/rustpi2/x-tools/arm-unknown-linux-gnueabihf/sysroot/usr/include/arm-linux-gnueabihf"
ENV OPENSSL_LIB_DIR=/opt/rustpi2/x-tools/arm-unknown-linux-gnueabihf/sysroot/usr/lib/arm-linux-gnueabihf

RUN mkdir -p dev/source

RUN mkdir dev/.cargo
RUN echo "[target.armv7-unknown-linux-gnueabihf]" > dev/.cargo/config
run echo "linker = \"rustpi-linker\"" >> dev/.cargo/config

WORKDIR /home/rustpi2/dev/source
