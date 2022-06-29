#!/usr/bin/env bash

# Build PostgreSQL Babelfish

set -x

set -eou pipefail

# Versions of Babelfish and extensions to pull from github
BABEL_PG='BABEL_1_2_0__PG_13_6'
BABEL_EXT='BABEL_1_2_0'

# Assume build dependencies are already installed (from Dockerfile)

BUILD_BASE="/build"

cd $BUILD_BASE
git clone --depth=1 --branch $BABEL_PG  https://github.com/babelfish-for-postgresql/postgresql_modified_for_babelfish.git 
git clone --depth=1 --branch $BABEL_EXT https://github.com/babelfish-for-postgresql/babelfish_extensions.git


cd "${BUILD_BASE}/postgresql_modified_for_babelfish"

./configure CFLAGS="${CFLAGS:--Wall -Wmissing-prototypes -Wpointer-arith -Wdeclaration-after-statement -Wendif-labels -Wmissing-format-attribute -Wformat-security -fno-strict-aliasing -fwrapv -fexcess-precision=standard -O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong --param=ssp-buffer-size=4 -grecord-gcc-switches -m64 -mtune=generic}" \
  --enable-thread-safety \
  --enable-cassert \
  --enable-debug \
  --with-ldap \
  --with-python \
  --with-libxml \
  --with-pam \
  --with-uuid=ossp \
  --enable-nls \
  --with-libxslt \
  --with-icu \
  --with-python PYTHON=/usr/bin/python2.7 \
  --with-extra-version=" Babelfish for PostgreSQL"


# All postgres binaries and extensions will be installed here
export INSTALLATION_PATH=/usr/local/pgsql
mkdir "$INSTALLATION_PATH"

# Build postgres
make

# Build postgres extensions
cd "${BUILD_BASE}/postgresql_modified_for_babelfish/contrib"
make

# Install PG and extensions to $INSTALLATION_PATH
cd "${BUILD_BASE}/postgresql_modified_for_babelfish"
make install
cd "${BUILD_BASE}/postgresql_modified_for_babelfish/contrib"
make install




# Build Babelfish PG extensions

curl -L https://github.com/Kitware/CMake/releases/download/v3.20.6/cmake-3.20.6-linux-x86_64.sh --output /opt/cmake-3.20.6-linux-x86_64.sh
chmod +x /opt/cmake-3.20.6-linux-x86_64.sh 
/opt/cmake-3.20.6-linux-x86_64.sh --prefix=/usr/local --skip-license


# Dowloads the compressed Antlr4 Runtime sources on /opt/antlr4-cpp-runtime-4.9.3-source.zip 
curl https://www.antlr.org/download/antlr4-cpp-runtime-4.9.3-source.zip \
  --output /opt/antlr4-cpp-runtime-4.9.3-source.zip 

# Uncompress the source into /opt/antlr4
unzip -d /opt/antlr4 /opt/antlr4-cpp-runtime-4.9.3-source.zip

mkdir /opt/antlr4/build 
cd /opt/antlr4/build

# Generates the make files for the build
EXTENSIONS_SOURCE_CODE_PATH="${BUILD_BASE}/babelfish_extensions"
cmake .. -DANTLR_JAR_LOCATION="$EXTENSIONS_SOURCE_CODE_PATH/contrib/babelfishpg_tsql/antlr/thirdparty/antlr/antlr-4.9.3-complete.jar" \
         -DCMAKE_INSTALL_PREFIX=/usr/local -DWITH_DEMO=True

# Compiles and install
make && make install
cp /usr/local/lib/libantlr4-runtime.so.4.9.3 "$INSTALLATION_PATH/lib"

export PG_CONFIG=/usr/local/pgsql/bin/pg_config
export PG_SRC="${BUILD_BASE}/postgresql_modified_for_babelfish"
export cmake=/usr/local/bin/cmake

cd "${BUILD_BASE}/babelfish_extensions/contrib"

# Install babelfishpg_money extension
cd "${BUILD_BASE}/babelfish_extensions/contrib/babelfishpg_money"
make && make install
# Install babelfishpg_common extension
cd "${BUILD_BASE}/babelfish_extensions/contrib/babelfishpg_common"
make && make install
# Install babelfishpg_tds extension
cd "${BUILD_BASE}/babelfish_extensions/contrib/babelfishpg_tds"
make && make install
# Installs the babelfishpg_tsql extension
cd "${BUILD_BASE}/babelfish_extensions/contrib/babelfishpg_tsql"
make && make install


# Strip debug symbols from all binaries and shared libs
strip /usr/local/pgsql/bin/* /usr/local/pgsql/lib/*.so /usr/local/pgsql/lib/*.so.*
