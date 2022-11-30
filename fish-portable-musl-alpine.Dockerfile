FROM alpine
VOLUME /result

ENV NCURSES_VER 6.3
ENV FISH_VER 3.5.1
ENV LDFLAGS -static

RUN apk update && apk add wget mc alpine-sdk git g++ make cmake ncurses ncurses-dev ncurses-libs xz

RUN mkdir -p /build /result
WORKDIR /build
RUN wget https://invisible-mirror.net/archives/ncurses/ncurses-$NCURSES_VER.tar.gz
RUN wget https://github.com/fish-shell/fish-shell/releases/download/$FISH_VER/fish-$FISH_VER.tar.xz
RUN tar xf fish-$FISH_VER.tar.xz && tar xf ncurses-$NCURSES_VER.tar.gz
RUN mkdir -p fish-$FISH_VER/build

WORKDIR /build/ncurses-$NCURSES_VER
RUN ./configure && make
RUN cp lib/libncurses.a /usr/lib/ && cp lib/libncurses.a /usr/lib/libcurses.a

COPY enable-static-linking.patch /tmp/enable-static-linking.patch
WORKDIR /build/fish-$FISH_VER
RUN patch -p1 -i /tmp/enable-static-linking.patch
WORKDIR /build/fish-$FISH_VER/build
# https://github.com/fish-shell/fish-shell/issues/6808#issuecomment-603992552
RUN mkdir /fish && cmake -DCMAKE_INSTALL_PREFIX=/fish -DCMAKE_BUILD_TYPE=Release  .. && make && make install
ADD fish.sh /fish/bin/
RUN chmod +x /fish/bin/fish.sh

WORKDIR /fish
CMD tar -zcf /result/fish-portable-musl-alpine-`uname`-`uname -m`.tar.gz * && ls -sh1 /result
