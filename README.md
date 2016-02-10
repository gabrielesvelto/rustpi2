# rustpi2

## What?

This is a shell script that helps building a Rust cross compilation toolchain targeting the Raspberry Pi 2 and similar boards (armv7 targets).

## Supported host environments

This has only been tested on Ubuntu 15.10 so far. If you use it successfully on other Linux distributions or on Mac OSX, please let me know!

## Supported target environments

The build script downloads packages for an up to date Raspian jessie distribution. This matters for openssl linkage only.

## Usage

This script depends on having the usual dev tools installed: git, curl, etc. It doesn't try to check if they are installed. You've been warned!

Run the `./build_toolchain.sh` command. It takes a single argument which is the path to the directory where the toolchain will be created. You need to have the permissions to create this directory.

Example: `./build_toolchain.sh /opt/rustpi2`

Once the toolchain is created, you can build for armv7 by doing the following:

1. Run `source ./rustpi-env.sh` to setup your environment.
2. In your Rust program's directory, build with: `cargopi build [options]`. This is equivalent to `cargo build [options] --target=armv7-unknown-linux-gnueabihf`.

Enjoy! :smile_cat:
