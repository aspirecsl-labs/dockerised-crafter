FROM alpine
LABEL maintainer="labs@aspirecsl.com"

# Make sure pipes are considered to determine success, see: https://github.com/hadolint/hadolint/wiki/DL4006
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

RUN apk add --no-cache git && \
    apk add --no-cache vim && \
    apk add --no-cache curl

CMD ["ash"]