FROM openjdk:8-jre-slim-buster
LABEL maintainer="labs@aspirecsl.com"

# Make sure pipes are considered to determine success, see: https://github.com/hadolint/hadolint/wiki/DL4006
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG VERSION

COPY id_rsa /
COPY sudoers /
COPY release /
COPY id_rsa.pub /
COPY crafter-http.conf /
COPY crafter-https.conf /
COPY docker-entrypoint.sh /
COPY docker-healthcheck.sh /
COPY crafter-self-signed.cert /
COPY crafter-self-signed.key /

RUN apt-get update && \
    apt-get install -y --no-install-recommends git && \
    apt-get install -y --no-install-recommends vim && \
    apt-get install -y --no-install-recommends bash && \
    apt-get install -y --no-install-recommends curl && \
    apt-get install -y --no-install-recommends lsof && \
    apt-get install -y --no-install-recommends sudo && \
    apt-get install -y --no-install-recommends rsync && \
    apt-get install -y --no-install-recommends procps && \
    apt-get install -y --no-install-recommends libaio1 && \
    apt-get install -y --no-install-recommends apache2 && \
    apt-get install -y --no-install-recommends iproute2 && \
    apt-get install -y --no-install-recommends libncurses5 && \
    apt-get install -y --no-install-recommends openssh-client && \
    DOWNLOAD_LINK="https://downloads.craftercms.org/${VERSION}/crafter-cms-delivery-${VERSION}.tar.gz" && \
    SHA512_DOWNLOAD_LINK="https://downloads.craftercms.org/${VERSION}/crafter-cms-delivery-${VERSION}.tar.gz.sha512" && \
    DOWNLOAD_TO="/tmp/crafter.tar.gz" && \
    SHA512_DOWNLOAD_TO="/tmp/crafter.tar.gz.sha512" && \
    echo "Downloading Crafter Delivery $VERSION" && \
    curl $DOWNLOAD_LINK --output $DOWNLOAD_TO && \
    curl $SHA512_DOWNLOAD_LINK --output ${SHA512_DOWNLOAD_TO} && \
    DOWNLOADED_INSTALLER_CHECKSUM=$(sha512sum $DOWNLOAD_TO | awk '{print($1)}') && \
    EXPECTED_INSTALLER_CHECKSUM=$(cat ${SHA512_DOWNLOAD_TO} | awk '{print($1)}') && \
    if [ "$EXPECTED_INSTALLER_CHECKSUM" != "$DOWNLOADED_INSTALLER_CHECKSUM" ]; \
    then \
        echo "Checksum mismatch on the downloaded crafter delivery bundle! exiting..." && \
        echo "" && \
        exit 1; \
    else \
        mkdir -p /opt/crafter/data \
                 /opt/crafter/backups \
                 /opt/crafter/temp/tomcat \
                 /opt/crafter/logs/tomcat \
                 /opt/crafter/logs/deployer \
                 /opt/crafter/logs/elasticsearch && \
        # adds crafter user and group to run crafter services
        groupadd -g 1000 -r crafter && \
        useradd -r -u 1000 -g crafter crafter && \
        tar -x -v -f $DOWNLOAD_TO && \
        cp -fr crafter/* /opt/crafter && \
        rm -fr crafter && \
        cp /sudoers /etc && \
        chmod 440 /etc/sudoers && \
        chown root:root /etc/sudoers && \
        cp /release /etc && \
        chmod 444 /etc/release && \
        chown root:root /etc/release && \
        chmod ugo+x /docker-entrypoint.sh \
                    /docker-healthcheck.sh && \
        chown -R crafter:crafter /opt/crafter \
                                 /docker-entrypoint.sh \
                                 /docker-healthcheck.sh && \
        service apache2 stop && \
        rm -f /etc/apache2/sites-enabled/* /etc/apache2/sites-available/* && \
        cp /crafter-http.conf /etc/apache2/sites-available && \
        ln -sf /etc/apache2/sites-available/crafter-http.conf /etc/apache2/sites-enabled/crafter-http.conf && \
        cp /crafter-https.conf /etc/apache2/sites-available && \
        ln -sf /etc/apache2/sites-available/crafter-https.conf /etc/apache2/sites-enabled/crafter-https.conf && \
        cp /crafter-self-signed.cert /etc/ssl/certs && chmod 644 /etc/ssl/certs/crafter-self-signed.cert && \
        cp /crafter-self-signed.key /etc/ssl/certs && chmod 600 /etc/ssl/certs/crafter-self-signed.key && \
        a2enmod ssl headers proxy_http && \
        mkdir -p /home/crafter/.ssh && mv /id_rsa* /home/crafter/.ssh && \
        chmod 700 /home/crafter/.ssh && chmod 600 /home/crafter/.ssh/id_rsa && chmod 644 /home/crafter/.ssh/id_rsa.pub && \
        chown -R crafter:crafter /home/crafter/.ssh && \
        rm -fr /var/lib/apt/lists/* $DOWNLOAD_TO ${SHA512_DOWNLOAD_TO}; \
    fi

EXPOSE \
    # http port
    80 \
    # https port
    443 \
    # JPDA debug port for Crafter Engine
    8000 \
    # Crafter engine port
    9080 \
    # Crafter deployer port
    9192 \
    # Elasticsearch port
    9202

VOLUME ["/opt/crafter/bin"]

USER crafter
WORKDIR /opt/crafter

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["run"]
HEALTHCHECK CMD /docker-healthcheck.sh
