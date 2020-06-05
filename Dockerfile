FROM openjdk:8-jre-slim-buster
# Make sure pipes are considered to determine success, see: https://github.com/hadolint/hadolint/wiki/DL4006
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG SERVICE
ARG VERSION
ARG CHECKSUM

ENV CRAFTER_HOME "/opt/crafter"
ENV DOWNLOAD_TO "/tmp/crafter-cms-$SERVICE-$VERSION.tar.gz"
ENV DOWNLOAD_LINK "https://downloads.craftercms.org/$VERSION/crafter-cms-$SERVICE-$VERSION.tar.gz"

COPY sudoers /
COPY entrypoint.sh /

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
    if [ "$CHECKSUM" != "$(sha512sum $DOWNLOAD_TO | awk '{print($1)}')" ]; \
    then \
        echo "checksum mismatch on the downloaded crafter $SERVICE bundle! exiting..." && \
        exit 1; \
    else \
        mkdir -p /opt/crafter \
                 /opt/crafter/bin \
                 /opt/crafter/data \
                 /opt/crafter/logs \
                 /opt/crafter/backups \
                 /opt/crafter/temp/tomcat && \
        groupadd -g 1000 -r crafter && \
        useradd -r -u 1000 -g crafter crafter && \
        tar -x -v -f $DOWNLOAD_TO && \
        cp -fr crafter/* /opt/crafter && \
        rm -fr crafter && \
        cp /sudoers /etc && \
        chmod 440 /etc/sudoers && \
        chown root:root /etc/sudoers && \
        chmod ugo+x /entrypoint.sh && \
        chown -R crafter:crafter /opt/crafter /entrypoint.sh; \
    fi; \
    rm -rf /var/lib/apt/lists/* $DOWNLOAD_TO

VOLUME ["/opt/crafter/data"]
VOLUME ["/opt/crafter/backups"]
EXPOSE \
# delivery
    9080 \
# authoring
    8080 \
# JPDA debug
    8000

USER crafter

ENTRYPOINT ["/entrypoint.sh"]
CMD ["run"]
HEALTHCHECK CMD curl -sSLf http://localhost:8080/studio >/dev/null || exit 1

