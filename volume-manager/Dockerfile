FROM alpine
LABEL maintainer="labs@aspirecsl.com"

# Make sure pipes are considered to determine success, see: https://github.com/hadolint/hadolint/wiki/DL4006
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

COPY release /

# Create crafter group and user
RUN addgroup --system --gid 1000 crafter && \
    adduser --system --uid 1000 --group crafter crafter && \
    mkdir -p /data && chown crafter:crafter /data && \
    chmod 444 /release

VOLUME ["/data"]

USER crafter
WORKDIR /data

CMD ["ash"]