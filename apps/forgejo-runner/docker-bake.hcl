target "docker-metadata-action" {}

variable "APP" {
  default = "forgejo-runner"
}

// Ubuntu release of the gitea/runner-images base image (see Dockerfile)
variable "VERSION" {
  default = "26.04"
}

variable "SOURCE" {
  default = "https://gitea.com/gitea/runner-images"
}

group "default" {
  targets = ["image-local"]
}

target "image" {
  inherits = ["docker-metadata-action"]
  args = {
    VERSION = "${VERSION}"
  }
  labels = {
    "org.opencontainers.image.source" = "${SOURCE}"
  }
}

target "image-local" {
  inherits = ["image"]
  output = ["type=docker"]
  tags = ["${APP}:${VERSION}"]
}

target "image-all" {
  inherits = ["image"]
  platforms = [
    "linux/amd64",
    "linux/arm64"
  ]
}
