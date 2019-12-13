#
# jdownloader-2 Dockerfile
#
# https://github.com/jlesage/docker-jdownloader-2
#
# ##############################################################################
# 7-Zip-JBinding Workaround
#
# JDownloader works well with the native openjdk8-jre package.  There is one
# exception: the auto archive extractor.  This feature uses 7-Zip-JBinding,
# which provides a platform-specific library (.so).  The one for Linux x86_64
# has been compiled against glibc and this is not loading correctly on Alpine.
#
# To work around this issue (until we get a proper support of 7-Zip-JBinding on
# Alpine), we need to:
#     - Get glibc, by using the glibc version of the baseimage.
#     - Use Oracle JRE, to have a glibc-based Java VM.
# ##############################################################################

# Pull base image.
# NOTE: glibc version of the image is needed for the 7-Zip-JBinding workaround.
FROM i386/alpine:3.9

# Docker image version is provided via build arg.
ARG DOCKER_IMAGE_VERSION=unknown

# Define software versions.
ARG JAVAJRE_VERSION=8.212.04.2

# Define software download URLs.
ARG JDOWNLOADER_URL=http://installer.jdownloader.org/JDownloader.jar
ARG JAVAJRE_URL=https://d3pxv6yz143wms.cloudfront.net/${JAVAJRE_VERSION}/amazon-corretto-${JAVAJRE_VERSION}-linux-x64.tar.gz

# Define GLIBC related variables.
ARG GLIBC_INSTALL=0
ARG GLIBC_ARCH=x86
ARG GLIBC_VERSION=2.26-r1
ARG GLIBC_URL=https://github.com/jlesage/glibc-bin-multiarch/releases/download/${GLIBC_VERSION}/glibc-bin-${GLIBC_VERSION}-${GLIBC_ARCH}.tar.gz
ARG GLIBC_LOCALE_INPUT=en_US
ARG GLIBC_LOCALE_CHARMAP=UTF-8
ARG GLIBC_LOCALE=${GLIBC_LOCALE_INPUT}.${GLIBC_LOCALE_CHARMAP}


# Define working directory.
WORKDIR /tmp

# Copy helpers.
COPY helpers/* /usr/local/bin/

# Install glibc if needed.
RUN \
    test "${GLIBC_INSTALL}" -eq 0 || ( \
    add-pkg --virtual build-dependencies curl binutils alpine-sdk && \
    # Download and install glibc.
    curl -# -L ${GLIBC_URL} | tar xz -C / && \
    # Strip symbols.
    find /usr/glibc-compat/bin -type f -exec strip {} ';' && \
    find /usr/glibc-compat/sbin -type f -exec strip {} ';' && \
    find /usr/glibc-compat/lib -type f -exec strip {} ';' && \
    # Create /etc/nsswitch.conf.
    echo -n "hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4" > /etc/nsswitch.conf && \
    # Create /usr/glibc-compat/etc/ld.so.conf
    echo "# libc default configuration" >> /usr/glibc-compat/etc/ld.so.conf && \
    echo "/usr/local/lib" >> /usr/glibc-compat/etc/ld.so.conf && \
    echo "/usr/glibc-compat/lib" >> /usr/glibc-compat/etc/ld.so.conf && \
    echo "/usr/lib" >> /usr/glibc-compat/etc/ld.so.conf && \
    echo "/lib" >> /usr/glibc-compat/etc/ld.so.conf && \
    # Create required symbolic links.
    mkdir -p /lib /lib64 /usr/glibc-compat/lib/locale && \
    ln -s /usr/glibc-compat/lib/ld-linux-x86-64.so.2 /lib/ld-linux-x86-64.so.2 && \
    ln -s /usr/glibc-compat/lib/ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2 && \
    ln -s /usr/glibc-compat/etc/ld.so.cache /etc/ld.so.cache && \
    # Run ldconfig.
    /usr/glibc-compat/sbin/ldconfig && \
    # Generate locale.
    /usr/glibc-compat/bin/localedef --inputfile ${GLIBC_LOCALE_INPUT} \
                                    --charmap ${GLIBC_LOCALE_CHARMAP} \
                                    ${GLIBC_LOCALE} && \
    # Timezone support.
    ln -s /usr/share/zoneinfo /usr/glibc-compat/share/zoneinfo && \
    # Add apk trigger.  This is needed so that ldconfig is called automatically
    # after apk installs libraries.
    echo 'pkgname=glibc-ldconfig-trigger' >> APKBUILD && \
    echo 'pkgver=1.0' >> APKBUILD && \
    echo 'pkgrel=0' >> APKBUILD && \
    echo 'pkgdesc="Dummy package that installs trigger for glibc ldconfig"' >> APKBUILD && \
    echo 'arch="noarch"' >> APKBUILD && \
    echo 'license="GPL"' >> APKBUILD && \
    echo 'makedepends=""' >> APKBUILD && \
    echo 'depends=""' >> APKBUILD && \
    echo 'install=""' >> APKBUILD && \
    echo 'subpackages=""' >> APKBUILD && \
    echo 'source=""' >> APKBUILD && \
    echo 'triggers="$pkgname.trigger=/lib:/usr/lib:/usr/glibc-compat/lib"' >> APKBUILD && \
    echo 'package() {' >> APKBUILD && \
    echo '        mkdir -p "$pkgdir"' >> APKBUILD && \
    echo '}' >> APKBUILD && \
    echo '#!/bin/sh' >> glibc-ldconfig-trigger.trigger && \
    echo '/usr/glibc-compat/sbin/ldconfig' >> glibc-ldconfig-trigger.trigger && \
    chmod +x glibc-ldconfig-trigger.trigger && \
    adduser -D -G abuild -s /bin/sh abuild && \
    su abuild -c "abuild-keygen -a -n" && \
    su abuild -c "abuild" && \
    cp /home/abuild/packages/*/glibc-ldconfig-trigger-1.0-r0.apk . && \
    apk --no-cache --allow-untrusted add glibc-ldconfig-trigger-1.0-r0.apk && \
    deluser --remove-home abuild && \
    # Remove unneeded stuff.
    rm /usr/glibc-compat/etc/rpc && \
    rm /usr/glibc-compat/lib/*.a && \
    rm -r /usr/glibc-compat/lib/audit && \
    rm -r /usr/glibc-compat/lib/gconv && \
    rm -r /usr/glibc-compat/lib/getconf && \
    rm -r /usr/glibc-compat/include && \
    rm -r /usr/glibc-compat/share/locale && \
    rm -r /usr/glibc-compat/share/i18n && \
    rm -r /usr/glibc-compat/var && \
    # Cleanup
    del-pkg build-dependencies && \
    rm -rf /tmp/* /tmp/.[!.]* )

# Download JDownloader 2.
RUN \
    mkdir -p /defaults && \
    wget ${JDOWNLOADER_URL} -O /defaults/JDownloader.jar

# Download and install Oracle JRE.
# NOTE: This is needed only for the 7-Zip-JBinding workaround.
RUN \
    apk add --virtual build-dependencies curl && \
    mkdir /opt/jre && \
    curl -# -L ${JAVAJRE_URL} | tar -xz --strip 2 -C /opt/jre amazon-corretto-${JAVAJRE_VERSION}-linux-x64/jre && \
    apk del build-dependencies

# Install dependencies.
RUN \
    apk add \
        # For the 7-Zip-JBinding workaround, Oracle JRE is needed instead of
        # the Alpine Linux's openjdk native package.
        # The libstdc++ package is also needed as part of the 7-Zip-JBinding
        # workaround.
        #openjdk8-jre \
        libstdc++ \
        ttf-dejavu \
        # For ffmpeg and ffprobe tools.
        ffmpeg \
        # For rtmpdump tool.
        rtmpdump

# Add files.
COPY rootfs/ /

# Set environment variables.
ENV APP_NAME="JDownloader 2" \
    S6_KILL_GRACETIME=8000

# Define mountable directories.
VOLUME ["/config"]
VOLUME ["/output"]

# Expose ports.
#   - 3129: For MyJDownloader in Direct Connection mode.
EXPOSE 3129

# Metadata.
LABEL \
      org.label-schema.name="jdownloader-2" \
      org.label-schema.description="Docker container for JDownloader 2" \
      org.label-schema.version="$DOCKER_IMAGE_VERSION" \
      org.label-schema.vcs-url="https://github.com/jlesage/docker-jdownloader-2" \
      org.label-schema.schema-version="1.0"

ENTRYPOINT /rootfs/startapp.sh