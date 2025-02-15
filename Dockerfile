############################
# Build Stage
############################
FROM golang:1.24.0 AS build
ARG TAG=0.0.1
WORKDIR /go/src/github.com/mindoc-org/mindoc

# 设置 Go 编译相关环境变量
ENV CGO_ENABLED=1

# 复制全部源码（通过 .dockerignore 排除无关文件）
COPY . .

# 编译、测试并清理不需要的文件（所有操作合并在一层中以减少层数）
RUN go env && \
    go mod tidy -v && \
    go build -v -o mindoc_linux_amd64 -ldflags "-w -s -X 'main.VERSION=${TAG}' -X 'main.BUILD_TIME=$(date)' -X 'main.GO_VERSION=$(go version)'" && \
    cp conf/app.conf.example conf/app.conf && \
    ./mindoc_linux_amd64 version && \
    rm -rf appveyor.yml docker-compose.yml Dockerfile .travis.yml .gitattributes .gitignore go.mod go.sum main.go README.md simsun.ttc start.sh conf/*.go && \
    rm -rf cache commands controllers converter .git .github graphics mail models routers utils

# 重新添加运行时所需的文件
COPY simsun.ttc /usr/share/fonts/win/simsun.ttc
COPY start.sh .

############################
# Final Stage
############################
FROM ubuntu:24.04
SHELL ["/bin/bash", "-c"]
WORKDIR /mindoc

# 从 build 阶段复制编译后的二进制及相关资源
COPY --from=build /go/src/github.com/mindoc-org/mindoc/mindoc_linux_amd64 /mindoc/
COPY --from=build /go/src/github.com/mindoc-org/mindoc/LICENSE.md /mindoc/
COPY --from=build /go/src/github.com/mindoc-org/mindoc/lib /mindoc/lib
COPY --from=build /go/src/github.com/mindoc-org/mindoc/conf /mindoc/__default_assets__/conf
COPY --from=build /go/src/github.com/mindoc-org/mindoc/static /mindoc/__default_assets__/static
COPY --from=build /go/src/github.com/mindoc-org/mindoc/views /mindoc/__default_assets__/views
COPY --from=build /go/src/github.com/mindoc-org/mindoc/uploads /mindoc/__default_assets__/uploads
COPY --from=build /go/src/github.com/mindoc-org/mindoc/start.sh /mindoc/
COPY --from=build /usr/share/fonts/win/simsun.ttc /usr/share/fonts/win/simsun.ttc

# 整合 apt 操作、时区、语言设置及 calibre 安装，合并为单个 RUN 层减少层数
RUN chmod a+r /usr/share/fonts/win/simsun.ttc && \
    chmod +x /mindoc/start.sh && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        apt-transport-https \
        curl \
        wget \
        xz-utils \
        tzdata \
        libgl-dev \
        libnss3-dev \
        libxcomposite-dev \
        libxrandr-dev \
        libxi-dev \
        libxdamage-dev \
        libxtst6 \
        libxkbcommon0 \
        libxkbfile1 \
        libegl1 \
        libopengl0 \
        fonts-wqy-microhei \
        fonts-wqy-zenhei \
        locales \
        language-pack-zh-hans \
        language-pack-zh-hans-base && \
    rm -rf /var/lib/apt/lists/* && \
    ln -snf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo "Asia/Shanghai" > /etc/timezone && \
    dpkg-reconfigure --frontend noninteractive tzdata && \
    locale-gen "zh_CN.UTF-8" && update-locale LANG=zh_CN.UTF-8 && \
    mkdir -p /tmp/calibre-cache && \
    wget -O /tmp/calibre-cache/calibre-x86_64.txz -c https://download.calibre-ebook.com/5.44.0/calibre-5.44.0-x86_64.txz && \
    mkdir -p /opt/calibre && \
    tar xJof /tmp/calibre-cache/calibre-x86_64.txz -C /opt/calibre && \
    rm -rf /tmp/calibre-cache && \
    export PATH=$PATH:/opt/calibre && \
    ebook-convert --version

# 定义持久化卷和容器暴露端口
VOLUME ["/mindoc/conf", "/mindoc/static", "/mindoc/views", "/mindoc/uploads", "/mindoc/runtime", "/mindoc/database"]
EXPOSE 8181/tcp

# 设置环境变量（如时区文件位置）
ENV ZONEINFO=/mindoc/lib/time/zoneinfo.zip

ENTRYPOINT ["/bin/bash", "/mindoc/start.sh"]
