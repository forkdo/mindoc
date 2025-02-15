#!/usr/bin/env bash

set -euo pipefail

# 资源路径列表
declare -A resources=(
    [conf]="/mindoc/conf"
    [static]="/mindoc/static"
    [views]="/mindoc/views"
    [uploads]="/mindoc/uploads"
)

# 初始化默认资源
for key in "${!resources[@]}"; do
    dir="${resources[$key]}"
    default_dir="/mindoc/__default_assets__/$key"

    mkdir -p "$dir"  # 确保目录存在
    [[ -z "$(ls -A -- "$dir")" ]] && cp -r "$default_dir" "/mindoc/"
done

# 如果配置文件不存在则复制
cp --no-clobber /mindoc/conf/app.conf.example /mindoc/conf/app.conf

# 数据库初始化
/mindoc/mindoc_linux_amd64 install

# 运行 Mindoc
exec /mindoc/mindoc_linux_amd64
