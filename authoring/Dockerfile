FROM alpine
LABEL maintainer="labs@aspirecsl.com"

# Make sure pipes are considered to determine success, see: https://github.com/hadolint/hadolint/wiki/DL4006
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

ARG VERSION
ARG DOWNLOAD_LINK
ARG SHA512_DOWNLOAD_LINK

ENV CRAFTER_VERSION $VERSION
ENV CRAFTER_HOME "/opt/crafter"

COPY sudoers /
COPY docker-entrypoint.sh /
COPY docker-healthcheck.sh /

RUN DOWNLOAD_TO="/tmp/crafter.tar.gz" && \
    SHA512_DOWNLOAD_TO="/tmp/crafter.tar.gz.sha512" && \
    apk add --no-cache git && \
    apk add --no-cache vim && \
    apk add --no-cache bash && \
    apk add --no-cache curl && \
    apk add --no-cache lsof && \
    apk add --no-cache sudo && \
    apk add --no-cache rsync && \
    apk add --no-cache libaio && \
    apk add --no-cache procps && \
    apk add --no-cache apache2 && \
    apk add --no-cache iproute2 && \
    apk add --no-cache ncurses5 && \
    apk add --no-cache openssh-client && \
    apk add --no-cache openjdk8-jre-base && \
    echo "Downloading Crafter Authoring $CRAFTER_VERSION" && \
    curl $DOWNLOAD_LINK --output $DOWNLOAD_TO && \
    curl $SHA512_DOWNLOAD_LINK --output ${SHA512_DOWNLOAD_TO} && \
    DOWNLOADED_INSTALLER_CHECKSUM=$(sha512sum $DOWNLOAD_TO | awk '{print($1)}') && \
    EXPECTED_INSTALLER_CHECKSUM=$(cat ${SHA512_DOWNLOAD_TO} | awk '{print($1)}') && \
    if [ "$EXPECTED_INSTALLER_CHECKSUM" != "$DOWNLOADED_INSTALLER_CHECKSUM" ]; \
    then \
        echo "Downloaded installer checksum:- $DOWNLOADED_INSTALLER_CHECKSUM" && \
        echo "Checksum mismatch on the downloaded crafter authoring bundle! exiting..." && \
        echo "" && \
        exit 1; \
    else \
        mkdir -p /opt/crafter \
                 /opt/crafter/bin \
                 /opt/crafter/backups \
                 /opt/crafter/temp/tomcat \
                 /opt/crafter/logs/tomcat \
                 /opt/crafter/logs/deployer \
                 /opt/crafter/data/indexes-es \
                 /opt/crafter/logs/elasticsearch && \
        # adds crafter user and group to run crafter services
        addgroup -S crafter && adduser -S crafter -G crafter && \
        tar -x -v -f $DOWNLOAD_TO && \
        cp -af crafter/* /opt/crafter && \
        rm -fR crafter && \
        cp /sudoers /etc && \
        chmod 440 /etc/sudoers && \
        chown root:root /etc/sudoers && \
        chmod ugo+x /docker-entrypoint.sh \
                    /docker-healthcheck.sh && \
        chown -R crafter:crafter /opt/crafter \
                                 /docker-entrypoint.sh \
                                 /docker-healthcheck.sh && \
        rm -fR $DOWNLOAD_TO ${SHA512_DOWNLOAD_TO}; \
    fi

EXPOSE \
    # Apache HTTP port
    80 \
    # Apache HTTPS port
    443 \
    # JPDA debug port for Elasticsearch
    4004 \
    # JPDA debug port for Crafter Deployer
    5005 \
    # JPDA debug port for Crafter Engine
    8000 \
    # Crafter engine port
    8080 \
    # Crafter deployer port
    9191 \
    # Elasticsearch port
    9201


USER crafter

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["run"]
HEALTHCHECK CMD /docker-healthcheck.sh

