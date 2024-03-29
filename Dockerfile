# nghttp2
# Copyright (c) 2012, 2014, 2015, 2016 Tatsuhiro Tsujikawa
# Copyright (c) 2012, 2014, 2015, 2016 nghttp2 contributors
# Licensed under the MIT license.
# (base: https://github.com/nghttp2/nghttp2/blob/v1.52.0/docker/Dockerfile)

FROM debian:11 as build

ENV NGHTTP2_VERSION=1.52.0

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git clang make binutils autoconf automake autotools-dev libtool \
        pkg-config \
        zlib1g-dev libev-dev libjemalloc-dev ruby-dev libc-ares-dev bison \
        libelf-dev

RUN git clone --depth 1 -b OpenSSL_1_1_1t+quic https://github.com/quictls/openssl && \
    cd openssl && \
    ./config --openssldir=/etc/ssl && \
    make -j$(nproc) && \
    make install_sw && \
    cd .. && \
    rm -rf openssl

RUN git clone --depth 1 -b v0.8.0 https://github.com/ngtcp2/nghttp3 && \
    cd nghttp3 && \
    autoreconf -i && \
    ./configure --enable-lib-only && \
    make -j$(nproc) && \
    make install-strip && \
    cd .. && \
    rm -rf nghttp3

RUN git clone --depth 1 -b v0.13.1 https://github.com/ngtcp2/ngtcp2 && \
    cd ngtcp2 && \
    autoreconf -i && \
    ./configure --enable-lib-only \
        LIBTOOL_LDFLAGS="-static-libtool-libs" \
        OPENSSL_LIBS="-l:libssl.a -l:libcrypto.a -ldl -lpthread" \
        PKG_CONFIG_PATH="/usr/local/lib64/pkgconfig" && \
    make -j$(nproc) && \
    make install-strip && \
    cd .. && \
    rm -rf ngtcp2

RUN git clone --depth 1 -b v1.1.0 https://github.com/libbpf/libbpf && \
    cd libbpf && \
    PREFIX=/usr/local make -C src install && \
    cd .. && \
    rm -rf libbpf

RUN git clone --depth 1 -b v${NGHTTP2_VERSION} https://github.com/nghttp2/nghttp2.git && \
    cd nghttp2 && \
    git submodule update --init && \
    autoreconf -i && \
    ./configure --disable-examples --disable-hpack-tools \
        --with-mruby --with-neverbleed \
        --enable-http3 --with-libbpf \
        CC=clang CXX=clang++ \
        LIBTOOL_LDFLAGS="-static-libtool-libs" \
        OPENSSL_LIBS="-l:libssl.a -l:libcrypto.a -ldl -pthread" \
        LIBEV_LIBS="-l:libev.a" \
        JEMALLOC_LIBS="-l:libjemalloc.a" \
        LIBCARES_LIBS="-l:libcares.a" \
        ZLIB_LIBS="-l:libz.a" \
        LIBBPF_LIBS="-L/usr/local/lib64 -l:libbpf.a -l:libelf.a" \
        LDFLAGS="-static-libgcc -static-libstdc++" \
        PKG_CONFIG_PATH="/usr/local/lib64/pkgconfig" && \
    make -j$(nproc) install-strip && \
    cd .. && \
    rm -rf nghttp2

FROM gcr.io/distroless/base-debian11

COPY --from=build \
    /usr/local/share/nghttp2/ \
    /usr/local/share/nghttp2/
COPY --from=build \
    /usr/local/bin/h2load \
    /usr/local/bin/nghttpx \
    /usr/local/bin/nghttp \
    /usr/local/bin/nghttpd \
    /usr/local/bin/
COPY --from=build /usr/local/lib/nghttp2/reuseport_kern.o \
    /usr/local/lib/nghttp2/
