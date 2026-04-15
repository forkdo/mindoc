#### Goreleaser ##########################################################
ARG GO_VERSION=1.25

FROM golang:${GO_VERSION} AS goreleaser

ARG GOPROXY=https://proxy.golang.org \
    CGO_ENABLED=1

RUN <<EOF
go install github.com/goreleaser/goreleaser/v2@latest
goreleaser --version
EOF

#### Build ##########################################################
FROM goreleaser AS builder

ARG VERSION=dev \
    GOPROXY=https://proxy.golang.org \
    CGO_ENABLED=1

WORKDIR /build
COPY . .

RUN <<EOF
if [ "$VERSION" = "dev" ]; then
    goreleaser --snapshot --clean
else
    goreleaser release --clean
fi

ARCH="$(uname -m)"
if [ "$ARCH" = "aarch64" ]; then
    ARCH="arm64"
fi
if [ "$ARCH" = "x86_64" ]; then
    ARCH="amd64"
fi

mkdir public
tar -zxf dist/*"${ARCH}".tar.gz -C public
mv public/mindoc .
EOF

#### Prod ##########################################################
FROM gcr.io/distroless/cc-debian12 AS prod

LABEL org.opencontainers.image.authors="Jetsung Chan<i@jetsung.com>"
LABEL org.opencontainers.image.documentation="https://github.com/forkdo/mindoc"

WORKDIR /mindoc

COPY --from=builder /build/mindoc /bin/
COPY --from=builder /build/public /mindoc/
COPY --from=builder /build/simsun.ttc /usr/share/fonts/win/

VOLUME /mindoc
EXPOSE 8181/tcp

ENTRYPOINT [ "mindoc" ]
