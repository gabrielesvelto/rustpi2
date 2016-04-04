#!/bin/bash

###############################################################################
# Option variables

opt_path=""
opt_rust_only=no
opt_help=no

###############################################################################
# Print the help message

print_help() {
    printf "Usage: `basename $0` [OPTION...] dest_dir

Application options:
  -r, --rust-only       Only rebuilds the rust cross-compiler

Help options:
  -h, --help            Show this help message
"
}

suggest_help() {
    printf "Try \``basename $0` --help' for more information\n"
}

###############################################################################
# Parse the program arguments

parse_args() {
    # Set the options variables depending on the passed arguments
    while [ $# -gt 0 ]; do
        if [ `expr "$1" : "^-"` -eq 1 ]; then
            if [ $1 = "-r" ] || [ $1 = "--rust-only" ]; then
                shift
                opt_rust_only=yes
            elif [ $1 = "-h" ] || [ $1 = "--help" ]; then
                opt_help=yes
                shift 1
            else
                printf "error: Unknown option $1\n"
                suggest_help
                exit 1
            fi
        else
            # No more arguments, the following parameters will be paths
            break
        fi
    done

    if [ $# -eq 0 ] && [ $opt_help != yes ]; then
        printf "error: no destination directory specified\n"
        suggest_help
        exit 1
    fi

    opt_path="$1"
}

OUR_CONTEXT=""

function cleanup {
    if [ ! -z $OUR_CONTEXT ];
    then
        printf "Removing: $OUR_CONTEXT\n"
        rm -f $HERE/deps/$OUR_CONTEXT
    fi
}
trap cleanup EXIT

# Check that all the required programs are installed
function check_programs {
  programs="cargo curl dpkg-deb git make"

  for i in $programs; do
    which $i 1>/dev/null 2>/dev/null

    if [ $? -ne 0 ]; then
        printf "error: $i not found, install it before running this script\n"
        exit 1;
    fi
  done
}

# Builds a full cross compiling toolchain for Rust armv7 targets like the
# Raspberry Pi 2, with support for programs using openssl.

parse_args "$@"
check_programs

if [ $opt_help = yes ] || [ $# -eq 0 ]; then
    print_help
    exit 0
fi

# Make crosstool-NG happy
unset LD_LIBRARY_PATH

# Downloads a deb file if we don't have a local version already.
function get_deb {
  if [ ! -f $HERE/deps/$2.deb ];
  then
    echo "Downloading package from http://archive.raspian.org/raspbian/pool/main/$1/$2.deb"
    curl https://archive.raspbian.org/raspbian/pool/main/$1/$2.deb -o $HERE/deps/$2.deb
  fi

  dpkg-deb -x $HERE/deps/$2.deb $HERE/deps/deb
}

# Update a repository if needed. Returns whether an update occured.
# call with : update_repo name url revision
function update_repo {
  NAME=$1
  URL=$2
  if [ -d ./deps/$NAME ];
  then
    (cd ./deps/$NAME && git pull --recurse-submodules=yes)
  else
    git clone --recursive $URL deps/$NAME
  fi
  pushd $HERE/deps/$NAME
  git checkout $3 .
  popd

  if [ -f ./deps/$NAME-commit ];
  then
    CURRENT_COMMIT=$(cat ./deps/$NAME-commit)
  else
    CURRENT_COMMIT="_"
  fi

  NEW_COMMIT=`git --git-dir=./deps/$NAME/.git log -1 --format=%H HEAD`
  echo $NEW_COMMIT > ./deps/$NAME-commit

  OUR_CONTEXT="$NAME-commit"

  if [ "$CURRENT_COMMIT" != "$NEW_COMMIT" ];
  then
    return 1
  else
    return 0
  fi
}

export DEST_DIR="$opt_path"
HERE=`pwd`

mkdir -p deps/deb
mkdir -p $DEST_DIR

export PATH=$DEST_DIR/bin:$DEST_DIR/x-tools/bin:$PATH

TARGET=armv7-unknown-linux-gnueabihf

# Clone and build crosstool-ng

if [ $opt_rust_only != yes ]; then
  update_repo crosstool-ng https://github.com/crosstool-ng/crosstool-ng.git HEAD

  if [ $? -eq 1 ];
  then
    (cd deps/crosstool-ng/ && ./bootstrap && ./configure --prefix=$DEST_DIR && make -j `nproc` && make install) || exit 1

    ct-ng build || exit 1
    cat build.log
    rm build.log
  fi
fi

OUR_CONTEXT=""

# Clone and build Rust

update_repo rust https://github.com/rust-lang/rust.git 998a6720b # HEAD

if [ $? -eq 1 ];
then
  (cd deps/rust && ./configure --prefix=$DEST_DIR --target=$TARGET && make -j `nproc` && make install) || exit 1
fi

OUR_CONTEXT=""

# Clone and build cargo

# Update PATH to get rustc
export PATH=$DEST_DIR/bin:$DEST_DIR/x-tools/bin:$PATH

update_repo cargo https://github.com/rust-lang/cargo.git

if [ $? -eq 1 ];
then
  (cd deps/cargo && ./configure --prefix=$DEST_DIR && make -j `nproc` && make install) || exit 1
fi

OUR_CONTEXT=""

# Download additional deb packages and patch the toolchain's sysroot.

get_deb a/alsa-lib libasound2_1.0.28-1_armhf
get_deb a/avahi libavahi-client-dev_0.6.31-5_armhf
get_deb a/avahi libavahi-common-dev_0.6.31-5_armhf
get_deb a/avahi libavahi-common3_0.6.31-5_armhf
get_deb d/dbus libdbus-1-dev_1.8.20-0+deb8u1_armhf
get_deb e/espeak libespeak-dev_1.48.04+dfsg-1_armhf
get_deb j/jackd2 libjack-jackd2-0_1.9.10+20140719git3eb0ae6a~dfsg-2_armhf
get_deb o/openssl libssl-dev_1.0.1k-3+deb8u4_armhf
get_deb o/openssl libssl1.0.0_1.0.1k-3+deb8u4_armhf
get_deb p/portaudio19 libportaudio2_19+svn20140130-1_armhf 
get_deb s/sonic libsonic0_0.1.17-1.1_armhf
get_deb s/sqlite3 libsqlite3-dev_3.8.7.1-1+deb8u1_armhf
get_deb z/zlib zlib1g_1.2.8.dfsg-2+b1_armhf
get_deb z/zlib zlib1g-dev_1.2.8.dfsg-2+b1_armhf
get_deb libu/libupnp libupnp6-dev_1.6.19+git20141001-1_armhf
get_deb libu/libupnp libupnp-dev_1.6.19+git20141001-1_all
get_deb libu/libupnp libupnp6_1.6.19+git20141001-1_armhf

DEB_LIBS=deps/deb/usr/lib/arm-linux-gnueabihf

# Hack to get libespeak dependencies available.
cp $DEB_LIBS/libsonic.so.0 $DEB_LIBS/libsonic.so
cp $DEB_LIBS/libportaudio.so.2.0.0 $DEB_LIBS/libportaudio.so
cp $DEB_LIBS/libjack.so.0.1.0 $DEB_LIBS/libjack.so
cp $DEB_LIBS/libasound.so.2.0.0 $DEB_LIBS/libasound.so

# We build libopenzwave ourselves and put the .so with the packaged libraries.
curl https://people.mozilla.org/~fdesre/link-packages/libopenzwave.so > deps/deb/lib/arm-linux-gnueabihf/libopenzwave.so

SYSROOT=$DEST_DIR/x-tools/arm-unknown-linux-gnueabihf/sysroot
chmod u+w $SYSROOT
chmod u+w $SYSROOT/lib
chmod u+w $SYSROOT/usr
chmod u+w $SYSROOT/usr/include
chmod u+w $SYSROOT/usr/share
chmod u+w $SYSROOT/usr/lib

cp -R ./deps/deb/lib $SYSROOT/
cp -R ./deps/deb/usr $SYSROOT/

chmod u-w $SYSROOT/usr/lib
chmod u-w $SYSROOT/usr/share
chmod u-w $SYSROOT/usr/include
chmod u-w $SYSROOT/usr
chmod u-w $SYSROOT/lib
chmod u-w $SYSROOT

# Adding the custom linker

cat > $DEST_DIR/bin/rustpi-linker <<EOF
#!/bin/bash
arm-linux-gnueabihf-gcc --sysroot=$SYSROOT -L $SYSROOT/usr/lib/arm-linux-gnueabihf -l ixml -l threadutil -l sonic -l portaudio -l jack -l asound "\$@"
EOF

chmod u+x $DEST_DIR/bin/rustpi-linker

# If the user has no .cargo/config file, create one. If not, prompt before adding.
# Should be replaced by something a bit more clever that actually parses the
# config file if it exists.

function create_cargo_config() {
  mkdir -p $HOME/.cargo
  cat > $HOME/.cargo/config <<EOF
[target.$TARGET]
linker = "rustpi-linker"
EOF
}

if [ ! -f $HOME/.cargo/config ];
then
  create_cargo_config
else
  LINKER=$(grep rustpi-linker $HOME/.cargo/config)
  if [ "$LINKER" == "" ];
  then
    echo "No linker found in your .cargo/config!"
  else
    echo "Current linker found: $LINKER"
  fi

  echo "Do you wish to update your cargo config file with target specific setup?"
  select yn in "Yes" "No"; do
      case $yn in
          Yes ) create_cargo_config; break;;
          No ) break;;
      esac
  done
fi

cp cargopi $DEST_DIR/bin

# Help people setup their environment. This creates a script to source before
# compiling.

cat > rustpi-env.sh <<EOF
#!/bin/bash
export PATH=$DEST_DIR/bin:$DEST_DIR/x-tools/bin:\$PATH
export LD_LIBRARY_PATH=$DEST_DIR/lib:\$LD_LIBRARY_PATH
export OPENSSL_LIB_DIR=$SYSROOT/usr/lib/arm-linux-gnueabihf/
export TARGET_CFLAGS="-I $SYSROOT/usr/include/arm-linux-gnueabihf"
EOF

echo "=================================================================="
echo " Run source ./rustpi-env.sh to setup your compilation environment."
echo "=================================================================="

# Check that we can compile and link a simple test program.

export LD_LIBRARY_PATH=$DEST_DIR/lib:$LD_LIBRARY_PATH
export OPENSSL_LIB_DIR=$SYSROOT/usr/lib/arm-linux-gnueabihf/
export TARGET_CFLAGS="-I $SYSROOT/usr/include/arm-linux-gnueabihf"

pushd test
cargo clean
cargo build --release --target=$TARGET

if [ $? -eq 0 ];
then
  echo "=================================================================="
  echo " Hooray! your toolchain works!"
  echo "=================================================================="
fi

popd

tar czf toolchain.tar.gz $DEST_DIR
