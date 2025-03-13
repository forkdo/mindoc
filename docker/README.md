# mindoc Docker 镜像

## Docker

| Registry        | Image        |
|---------------------------|----------------------------|
| [**Docker Hub**](https://hub.docker.com/r/forkdo/mindoc)                                           | `forkdo/mindoc`          
| [**GitHub Container Registry**](https://github.com/forkdo/mindoc/pkgs/container/mindoc)            | `ghcr.io/forkdo/mindoc` 
| **Tencent Cloud Container Registry** | `ccr.ccs.tencentyun.com/forkdo/mindoc`
| **Aliyun Container Registry** | `crpi-6q2ncgoagz57loxj.cn-guangzhou.personal.cr.aliyuncs.com/forkdo/mindoc`

```bash
docker pull forkdo/mindoc:latest

# ghcr.io
docker pull ghcr.io/forkdo/mindoc:latest

# Tencent Cloud Container Registry
docker pull ccr.ccs.tencentyun.com/forkdo/mindoc:latest

# Aliyun Container Registry
docker pull docker pull crpi-6q2ncgoagz57loxj.cn-guangzhou.personal.cr.aliyuncs.com/forkdo/mindoc:latest
```

## 构建教程：

### 完整版：`latest`（1GB）

基础镜像为 **`debian:12-slim`**。构建时**会**自动安装 **Calibre**，支持导出功能。

**构建命令：**
```bash
docker build -f docker/Dockerfile -t mindoc:latest .
```

### 稳定版：`stable` (150MB)
基础镜像为 **`debian:12-slim`**。构建时**不会**自动安装 **Calibre** ，支持后期安装。

**构建命令：**
```bash
docker build -f docker/Dockerfile-stable -t mindoc:stable .
```

### 精简版：`slim`（130MB）

基础镜像为 `gcr.io/distroless/cc-debian12`，不支持导出功能（**Calibre**），不支持 **shell** 命令。

**构建命令：**
```bash
docker build -f docker/Dockerfile-slim -t mindoc:slim .
```

## 使用教程：

> 初始账号：`admin`   
> 初始密码：`123456`   

### 首次使用

[**完整版**](Dockerfile)
1. 初始化数据库
若使用非 SQLite 数据库，需自行修改 `conf/app.conf` 文件中的数据库配置信息。

```bash
docker run --rm -v $(pwd)/mindoc:/mindoc mindoc:latest install
```

2. 启动服务
```bash
docker run -d -e TZ=Asia/Shanghai -v $(pwd)/mindoc:/mindoc -p 8181:8181 --name mindoc mindoc:latest
```

**直接一步到位（第 `1+2` 步）**
```bash
docker run -d -e TZ=Asia/Shanghai -v $(pwd)/mindoc:/mindoc -p 8181:8181 --name mindoc mindoc:latest start
```

[**稳定版**](Dockerfile-stable)
1. 初始化数据库
若使用非 SQLite 数据库，需自行修改 `conf/app.conf` 文件中的数据库配置信息。

```bash
docker run --rm -v $(pwd)/mindoc:/mindoc mindoc:stable install
```

2. 启动服务
```bash
docker run -d -e TZ=Asia/Shanghai -v $(pwd)/mindoc:/mindoc -p 8181:8181 --name mindoc mindoc:stable

# 支持 Calibre 导出方式启动（需要使用网络安装 Calibre）
docker run -d -e TZ=Asia/Shanghai -v $(pwd)/mindoc:/mindoc -p 8181:8181 --name mindoc mindoc:stable calibre
```

**直接一步到位（第 `1+2` 步）**
```bash
docker run -d -e TZ=Asia/Shanghai -v $(pwd)/mindoc:/mindoc -p 8181:8181 --name mindoc mindoc:stable start

# 支持 Calibre 导出方式启动（需要使用网络安装 Calibre）
docker run -d -e TZ=Asia/Shanghai -v $(pwd)/mindoc:/mindoc -p 8181:8181 --name mindoc mindoc:stable start calibre
```

[**精简版**](Dockerfile-slim)

1. 需将基本目录文件复制到本地，以支持持久化。
```bash
# 最小版
docker create --name extract mindoc:slim

docker cp extract:/mindoc mindoc
docker rm -f extract
```
    亦可按实际需求挂载对应目录。

2. 初始化数据库
若使用非 SQLite 数据库，需自行修改 `conf/app.conf` 文件中的数据库配置信息。

```bash
docker run --rm -v $(pwd)/mindoc:/mindoc mindoc:slim install
```

3. 启动服务（若已初始化文件、数据库，可直接忽略第 1、2 步）
```bash
docker run -d -e TZ=Asia/Shanghai -v $(pwd)/mindoc:/mindoc -p 8181:8181 --name mindoc mindoc:slim

# 指定挂载目录
docker run -d -e TZ=Asia/Shanghai -v /mindoc/conf:/mindoc/conf -p 8181:8181 --name mindoc mindoc:slim
```

## docker-compose.yml 示例：
> 需已初始化文件、数据库
```yaml
services:
  mindoc:
    image: forkdo/mindoc:latest
    container_name: mindoc
    restart: unless-stopped
    ports:
      - 8181:8181
    volumes:
      - ./mindoc/conf:/mindoc/conf
      - ./mindoc/static:/mindoc/static
      - ./mindoc/views:/mindoc/views
      - ./mindoc/uploads:/mindoc/uploads
      - ./mindoc/runtime:/mindoc/runtime
      - ./mindoc/database:/mindoc/database
    environment:
      - TZ=Asia/Shanghai
      - MINDOC_RUN_MODE=prod
      - MINDOC_DB_ADAPTER=sqlite3
      - MINDOC_DB_DATABASE=./database/mindoc.db
      - MINDOC_CACHE=true
      - MINDOC_CACHE_PROVIDER=file
      - MINDOC_ENABLE_EXPORT=false
      - MINDOC_BASE_URL=
      - MINDOC_CDN_IMG_URL=
      - MINDOC_CDN_CSS_URL=
      - MINDOC_CDN_JS_URL=
```

**一步到位**
```yaml
services:
  mindoc:
    image: forkdo/mindoc:latest
    container_name: mindoc
    restart: unless-stopped
    ports:
      - 8181:8181
    volumes:
      -./mindoc:/mindoc
    command: ["start", "calibre"]
```

```bash
# 配置
/mindoc/conf

# 静态文件
/mindoc/static

# 视图文件
/mindoc/views

# 上传文件
/mindoc/uploads

# 运行时文件（比如临时文件）
/mindoc/runtime

# 数据库文件（SQLite 持久化）
/mindoc/database
```

更多参数请参考 [配置文件](../conf/app.conf.example)。