FROM centos:7

RUN yum -y install epel-release \
    && yum -y update && yum -y upgrade \
    && yum -y install gcc gcc-c++ glibc-devel make ncurses-devel openssl-devel autoconf

ENV ERLANG_VERSION=21.1.3 \
    ELIXIR_VERSION="v1.6.5" \
    LANG=en_US.UTF-8

WORKDIR /tmp/erlang-build

RUN curl -fSL -o OTP-$ERLANG_VERSION.tar.gz https://github.com/erlang/otp/archive/OTP-$ERLANG_VERSION.tar.gz \
    && tar --strip-components=1 -zxf OTP-$ERLANG_VERSION.tar.gz \
    && rm OTP-$ERLANG_VERSION.tar.gz \
    && ./otp_build autoconf && \
        export ERL_TOP=/tmp/erlang-build && \
        export PATH=$ERL_TOP/bin:$PATH && \
        export CPPFlAGS="-D_BSD_SOURCE $CPPFLAGS" && \
        ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --mandir=/usr/share/man \
        --infodir=/usr/share/info \
        --without-javac \
        --without-wx \
        --without-debugger \
        --without-observer \
        --without-jinterface \
        --without-cosEvent\
        --without-cosEventDomain \
        --without-cosFileTransfer \
        --without-cosNotification \
        --without-cosProperty \
        --without-cosTime \
        --without-cosTransactions \
        --without-et \
        --without-gs \
        --without-ic \
        --without-megaco \
        --without-orber \
        --without-percept \
        --without-typer \
        --enable-threads \
        --enable-shared-zlib \
        --enable-ssl=dynamic-ssl-lib \
        --enable-fips \
    && make -j7

## Elixir
WORKDIR /tmp/elixir-build

RUN set -xe \
    && ELIXIR_DOWNLOAD_URL="https://github.com/elixir-lang/elixir/archive/${ELIXIR_VERSION#*@}.tar.gz" \
    && ELIXIR_DOWNLOAD_SHA256="3258eca6b5caa5e98b67dd033f9eb1b0b7ecbdb7b0f07c111b704700962e64cc" \
    && curl -fSL -o elixir-src.tar.gz $ELIXIR_DOWNLOAD_URL \
    && echo "$ELIXIR_DOWNLOAD_SHA256  elixir-src.tar.gz" | sha256sum -c - \
    && tar --strip-components=1 -zxf elixir-src.tar.gz \
    && rm elixir-src.tar.gz \
    && make

FROM centos:7

RUN cd /tmp/erlang-build && export ERL_TOP=/tmp/erlang-build && time make install

RUN cd /tmp/elixir-build && time make install

RUN rm -rf /tmp/erlang-build && rm -rf /tmp/elixir-build