target "docker-metadata-action" {}

variable "APP" {
  default = "unifi-api-browser"
}

variable "VERSION" {
  // renovate: datasource=github-releases depName=Art-of-WiFi/UniFi-API-browser
  default = "v3.0.0"
}

variable "SOURCE" {
  default = "https://github.com/Art-of-WiFi/UniFi-API-browser"
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
    "org.opencontainers.image.title" = "unifi-api-browser"
    "org.opencontainers.image.description" = "UniFi API Browser container with env-based config and users rendering"
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
