ARG VERSION=0.64.0
ARG ALPINE_VERSION=3.11.5

FROM alpine:${ALPINE_VERSION} AS builder

ARG VERSION

LABEL maintainer="psellars@gmail.com"

RUN apk add --no-cache \
    curl \
    git \
    openssh-client \
    rsync 

WORKDIR /usr/local/src
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

RUN echo ${VERSION}

RUN wget \
  https://github.com/gohugoio/hugo/releases/download/v"${VERSION}"/hugo_"${VERSION}"_Linux-64bit.tar.gz

RUN wget \
  https://github.com/gohugoio/hugo/releases/download/v"${VERSION}"/hugo_"${VERSION}"_checksums.txt \
    && sed -i '/hugo_[0-9].*Linux-64bit.tar.gz/!d' "hugo_${VERSION}_checksums.txt" \
    && sha256sum -cs "hugo_${VERSION}_checksums.txt" \
    && tar -xzvf hugo_"${VERSION}"_Linux-64bit.tar.gz 

FROM alpine:${ALPINE_VERSION}

ARG VERSION
ARG TINI_VERSION=~0.18.0

ARG CREATE_DATE
ARG REVISION
ARG BUILD_VERSION

LABEL maintainer="psellars@gmail.com"

LABEL org.opencontainers.image.create_date=$CREATE_DATE
LABEL org.opencontainers.image.title="hugo_builder"
LABEL org.opencontainers.image.source="https://github.com/psellars/docker-container-security-lp"
LABEL org.opencontainers.image.revision=$REVISION 
LABEL org.opencontainers.image.version=$BUILD_VERSION 
LABEL org.opencontainers.image.licenses="Apache-2.0" 
LABEL hugo_version=$VERSION

RUN apk --no-cache add \
  tini=${TINI_VERSION}

COPY --from=builder /usr/local/src/hugo /usr/local/bin/

RUN addgroup -Sg 1000 hugo \
  && adduser -SG hugo -u 1000 -h /src hugo

USER hugo

WORKDIR /src

EXPOSE 1313
ENTRYPOINT ["/sbin/tini","--"]

HEALTHCHECK --interval=10s --timeout=10s --start-period=15s \
  CMD hugo env || exit 1
