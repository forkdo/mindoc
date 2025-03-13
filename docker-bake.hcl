variable "GO_VERSION" {
  default = "1.24"
}

variable "GO_PROXY" {
    default = "https://goproxy.cn"
}

variable "GHCR_REGISTRY" {
    default = "ghcr.io/forkdo/mindoc"
}

## Special target: https://github.com/docker/metadata-action#bake-definition
target "docker-metadata-action" {}

target "_image" {
    inherits = ["docker-metadata-action"]
}

target "_common" {
    labels = {
        "org.opencontainers.image.source" = "https://github.com/forkdo/mindoc"
        "org.opencontainers.image.documentation" = "https://github.com/forkdo/mindoc/tree/main/docker"
        "org.opencontainers.image.authors" = "Jetsung Chan<i@jetsung.com>"
    }
    context = "."    
    args = {
        GO_VERSION="${GO_VERSION}"
        GOPROXY = "${GO_PROXY}"
    }   
    platforms = ["linux/amd64"]    
}

#########################################################
target "dev" {
    name = "dev-${item.tgt}"
    matrix = {
        item = [
            {
                tgt = "latest"
                file = ""
                tag = "dev"
            },
            {
                tgt = "lite"
                file = "lite."
                tag = "dev-lite"
            },
            {
                tgt = "slim"
                file = "slim."
                tag = "dev-slim"
            }
        ]
    }
    inherits = ["_common", "_image"]    
    dockerfile = "docker/${item.file}Dockerfile" 
    tags =  ["${GHCR_REGISTRY}:${item.tag}"]
}
#########################################################