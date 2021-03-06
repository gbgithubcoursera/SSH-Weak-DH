FROM alpine:3.8
WORKDIR /app
COPY resources/openssh.patch .
COPY resources/bsd-compatible-realpath.patch .
RUN OPENSSH_VERSION='7.3p1' && \
    ARCHIVE_SHA_256='3ffb989a6dcaa69594c3b550d4855a5a2e1718ccdde7f5e36387b424220fbecc' && \
    apk add --no-cache bash libressl python3 && \
    ln -s /usr/bin/python3 /usr/bin/python && \
    apk add --no-cache --virtual .build-deps \
      build-base curl libressl-dev linux-headers zlib-dev && \
    curl -s -O "https://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-${OPENSSH_VERSION}.tar.gz" && \
    CHECKSUM=$(sha256sum "openssh-${OPENSSH_VERSION}.tar.gz" | awk '{print $1;}') && \
    echo "Checksum is $CHECKSUM" && \
    [ "$CHECKSUM" == "$ARCHIVE_SHA_256" ] && \
    echo "Checksum is valid" && \
    tar xzf "openssh-${OPENSSH_VERSION}.tar.gz" && \
    rm -f "openssh-${OPENSSH_VERSION}.tar.gz" && \
    cd "openssh-${OPENSSH_VERSION}" && \
    patch -p1 < ../openssh.patch && \
    patch -p1 < ../bsd-compatible-realpath.patch && \
    ./configure && \
    make ssh && \
    cp ssh .. && \
    cd .. && \
    rm -rf "openssh-${OPENSSH_VERSION}/" *.patch && \
    apk del .build-deps
COPY resources/ssh-weak-dh-analyze.py .
COPY resources/ssh-weak-dh-test.sh .
COPY resources/configs/ configs/
VOLUME /logs
ENV PYTHONUNBUFFERED=1
ENTRYPOINT ["bash", "ssh-weak-dh-test.sh"]
