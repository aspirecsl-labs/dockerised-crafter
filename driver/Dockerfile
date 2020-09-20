FROM alpine
LABEL maintainer="labs@aspirecsl.com"

# Make sure pipes are considered to determine success, see: https://github.com/hadolint/hadolint/wiki/DL4006
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

COPY site.sh /
COPY release /etc
COPY engine /engine
COPY studio /studio
COPY docker-entrypoint.sh /

# Create crafter group and user
RUN apk update && \
    apk add --no-cache git curl && \
    addgroup -S -g 1000 crafter && \
    adduser -S -u 1000 -G crafter crafter && \
    chmod 444 /etc/release && \
    chmod -R ugo+x /engine \
                   /studio \
                   /site.sh \
                   /docker-entrypoint.sh

USER crafter

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["version"]