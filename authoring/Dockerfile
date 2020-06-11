FROM openjdk:8-jre-slim-buster
# Make sure pipes are considered to determine success, see: https://github.com/hadolint/hadolint/wiki/DL4006
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG VERSION
ARG INSTALLER_CHECKSUM

ENV CRAFTER_VERSION $VERSION
ENV CRAFTER_HOME "/opt/crafter"
ENV DOWNLOAD_TO "/tmp/crafter-cms-authoring-$CRAFTER_VERSION.tar.gz"
ENV DOWNLOAD_LINK "https://downloads.craftercms.org/$CRAFTER_VERSION/crafter-cms-authoring-$CRAFTER_VERSION.tar.gz"

COPY sudoers /
COPY docker-entrypoint.sh /
COPY docker-healthcheck.sh /
COPY crafter-entrypoint.sh /

RUN apt-get update && \
    apt-get install -y --no-install-recommends git && \
    apt-get install -y --no-install-recommends vim && \
    apt-get install -y --no-install-recommends sudo && \
    apt-get install -y --no-install-recommends curl && \
    apt-get install -y --no-install-recommends wget && \
    apt-get install -y --no-install-recommends lsof && \
    apt-get install -y --no-install-recommends rsync && \
    apt-get install -y --no-install-recommends procps && \
    apt-get install -y --no-install-recommends apache2 && \
    apt-get install -y --no-install-recommends libaio1 && \
    apt-get install -y --no-install-recommends iproute2 && \
    apt-get install -y --no-install-recommends libncurses5 && \
    apt-get install -y --no-install-recommends openssh-client && \
    wget --output-document=$DOWNLOAD_TO $DOWNLOAD_LINK && \
    DOWNLOADED_INSTALLER_CHECKSUM=$(sha512sum $DOWNLOAD_TO | awk '{print($1)}') && \
    if [ "$INSTALLER_CHECKSUM" != "$DOWNLOADED_INSTALLER_CHECKSUM" ]; \
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
        groupadd -g 1000 -r crafter && \
        useradd -r -u 1000 -g crafter crafter && \
        tar -x -v -f $DOWNLOAD_TO && \
        cp -fr crafter/* /opt/crafter && \
        rm -fr crafter && \
        cp /sudoers /etc && \
        chmod 440 /etc/sudoers && \
        chown root:root /etc/sudoers && \
        chmod ugo+x /docker-entrypoint.sh \
                    /docker-healthcheck.sh \
                    /crafter-entrypoint.sh && \
        chown -R crafter:crafter /opt/crafter \
                                 /docker-entrypoint.sh \
                                 /docker-healthcheck.sh \
                                 /crafter-entrypoint.sh; \
    fi; \
    rm -rf /var/lib/apt/lists/* $DOWNLOAD_TO

VOLUME ["/opt/crafter/logs"]
VOLUME ["/opt/crafter/data"]
VOLUME ["/opt/crafter/backups"]

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

