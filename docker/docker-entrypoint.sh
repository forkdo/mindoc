#!/usr/bin/env bash

set -euo pipefail

# 安装 Calibre
install_calibre() {
    if ! command -v calibre >/dev/null 2>&1; then
      echo "Installing calibre"
      echo ""
      apt update && \
      apt install -y --no-install-recommends calibre && \
      apt clean && \
      rm -rf /var/lib/apt/lists/*
    fi    
}

cd /mindoc

mkdir -p /mindoc/conf

[[ -d /mindoc/conf/lang ]] || mv /temp/conf/lang /mindoc/conf/
[[ -f /mindoc/conf/app.conf ]] || mv /temp/conf/app.conf /mindoc/conf/
[[ -d /mindoc/static ]] || mv /temp/static /mindoc/
[[ -d /mindoc/uploads ]] || mv /temp/uploads /mindoc/
[[ -d /mindoc/views ]] || mv /temp/views /mindoc/

if [[ "$#" -gt 0 ]]; then

    # 初始化数据库
    if [[ "$1" == "install" ]]; then
      mindoc install
      exit 0
    fi

    # 安装 calibre
    if [[ "$1" == "calibre" ]]; then
      install_calibre

      mindoc
      exit 0
    fi

    # 一体化运行：初始化数据库 + 安装 calibre
    if [[ "$1" == "start" ]]; then
      # 第二个参数为 calibre 时，安装 calibre
      if [[ "${2:-}" == "calibre" ]]; then
        install_calibre
      fi

      # 初始化数据库
      mindoc install

      # 启动服务
      mindoc
      exit 0
    fi

    exec -- "$@"
    exit 0
fi

mindoc
