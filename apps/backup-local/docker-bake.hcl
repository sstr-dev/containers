target "docker-metadata-action" {}

variable "APP" {
  default = "backup-local"
}

variable "VERSION" {
  // renovate: datasource=docker depName=docker.io/library/postgres versioning=docker
  default = "18.3-alpine3.23"
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
    "org.opencontainers.image.title"       = "backup-local"
    "org.opencontainers.image.description" = "Local PostgreSQL and MariaDB backup container for Kubernetes jobs"
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
