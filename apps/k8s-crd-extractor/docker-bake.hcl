target "docker-metadata-action" {}

variable "APP" {
  default = "k8s-crd-extractor"
}

variable "VERSION" {
  // datreeio/CRDs-catalog commit (no releases upstream, bump manually)
  default = "b1c3c987a74c0160d0e6190ad1c53d13e8fcfc06"
}

variable "SOURCE" {
  default = "https://github.com/datreeio/CRDs-catalog"
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
