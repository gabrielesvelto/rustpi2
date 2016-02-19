# rustci20

## What?

This is a shell script that helps building a Rust cross compilation toolchain targeting the Creator Ci20 and similar boards (mipsel targets).

## Supported host environments

This has only been tested on Ubuntu 15.10 and Gentoo so far. If you use it successfully on other Linux distributions or on Mac OSX, please let me know!

## Supported target environments

The build script downloads packages for an up to date Debian jessie distribution. This matters for openssl linkage only.

## Required dependencies

This script depends on having the usual dev tools installed. It doesn't try to check if they are all installed. You've been warned!

### Fedora

Make sure you have the package glibc-static installed for libc.a.

## Usage

Run the `./build_toolchain.sh` command. It takes a single argument which is the path to the directory where the toolchain will be created. You need to have the permissions to create this directory.

Example: `./build_toolchain.sh /opt/rustci20`

Once the toolchain is created, you can build for mipsel by doing the following:

1. Run `source ./rustci20-env.sh` to setup your environment.
2. In your Rust program's directory, build with: `cargoci20 build [options]`. This is equivalent to `cargo build [options] --target=mipsel-unknown-linux-gnu`.

Enjoy! :smile_cat:
