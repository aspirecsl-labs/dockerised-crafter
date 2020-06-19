FROM alpine
LABEL maintainer="labs@aspirecsl.com"

# Make sure pipes are considered to determine success, see: https://github.com/hadolint/hadolint/wiki/DL4006
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

COPY site.sh /
COPY release /

# Create crafter group and user
RUN addgroup -S -g 1000 crafter && \
    adduser -S -u 1000 -G crafter crafter && \
    mkdir -p /data && chown crafter:crafter /data && \
    chmod 444 /release && chmod ugo+x /site.sh

VOLUME ["/data"]

USER crafter
WORKDIR /data

CMD ["ash"]