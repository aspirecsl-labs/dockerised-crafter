FROM openjdk:8-jre-slim-buster
# Make sure pipes are considered to determine success, see: https://github.com/hadolint/hadolint/wiki/DL4006
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG MAIN_PORT
ARG AUX_PORTS
ARG CRAFTER_SERVICE
ARG CRAFTER_VERSION
ARG CRAFTER_INSTALLER_CHECKSUM

ENV SERVICE_PORT $MAIN_PORT
ENV CRAFTER_HOME "/opt/crafter"
ENV DOWNLOAD_TO "/tmp/crafter-cms-$CRAFTER_SERVICE-$CRAFTER_VERSION.tar.gz"
ENV DOWNLOAD_LINK "https://downloads.craftercms.org/$CRAFTER_VERSION/crafter-cms-$CRAFTER_SERVICE-$CRAFTER_VERSION.tar.gz"

COPY sudoers /
COPY crafter-entrypoint.sh /
COPY docker-entrypoint.sh /

RUN apt-get update && \
    apt-get install -y --no-install-recommends git && \
    apt-get install -y --no-install-recommends vim && \
    apt-get install -y --no-install-recommends sudo && \
    apt-get install -y --no-install-recommends curl && \
    apt-get install -y --no-install-recommends wget && \
    apt-get install -y --no-install-recommends lsof && \
    apt-get install -y --no-install-recommends rsync && \
    apt-get install -y --no-install-recommends procps && \
    apt-get install -y --no-install-recommends libaio1 && \
    apt-get install -y --no-install-recommends iproute2 && \
    apt-get install -y --no-install-recommends libncurses5 && \
    apt-get install -y --no-install-recommends openssh-client && \
    wget --output-document=$DOWNLOAD_TO $DOWNLOAD_LINK && \
    if [ "$CRAFTER_INSTALLER_CHECKSUM" != "$(sha512sum $DOWNLOAD_TO | awk '{print($1)}')" ]; \
    then \
        echo "checksum mismatch on the downloaded crafter $CRAFTER_SERVICE bundle! exiting..." && \
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
        chmod ugo+x /docker-entrypoint.sh && \
        chmod ugo+x /crafter-entrypoint.sh && \
        chown -R crafter:crafter /opt/crafter /docker-entrypoint.sh /crafter-entrypoint.sh; \
    fi; \
    rm -rf /var/lib/apt/lists/* $DOWNLOAD_TO

VOLUME ["/opt/crafter/logs"]
VOLUME ["/opt/crafter/data"]
VOLUME ["/opt/crafter/backups"]

# Expose the following service ports
# 1. Delivery main port (default: 9080) if delivery server
# 2. Authoring main port (default: 8080) if authoring server
# 3. JPDA debug port (default 8000) for both delivery and authoring servers
EXPOSE $SERVICE_PORT $AUX_PORTS

USER crafter

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["run"]
HEALTHCHECK CMD curl -sSLf http://localhost:$SERVICE_PORT >/dev/null || exit 1

