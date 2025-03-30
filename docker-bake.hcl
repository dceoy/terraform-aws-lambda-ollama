variable "REGISTRY" {
  default = "123456789012.dkr.ecr.us-east-1.amazonaws.com"
}

variable "TAG" {
  default = "latest"
}

variable "AWS_LAMBDA_PROVIDED_IMAGE_TAG" {
  default = "al2023"
}

variable "AWS_LAMBDA_ADAPTER_VERSION" {
  default = "0.9.0"
}

variable "USER_UID" {
  default = 1001
}

variable "USER_GID" {
  default = 1001
}

variable "USER_NAME" {
  default = "lambda"
}

variable "OLLAMA_MODEL_NAME" {
  default = "llama3.2:1b"
}

group "default" {
  targets = ["ollama-serve"]
}

target "ollama-serve" {
  tags       = ["${REGISTRY}/ollama-serve:${TAG}"]
  context    = "./src"
  dockerfile = "Dockerfile"
  target     = "app"
  platforms  = ["linux/arm64"]
  args = {
    AWS_LAMBDA_PROVIDED_IMAGE_TAG = AWS_LAMBDA_PROVIDED_IMAGE_TAG
    AWS_LAMBDA_ADAPTER_VERSION    = AWS_LAMBDA_ADAPTER_VERSION
    USER_UID                      = USER_UID
    USER_GID                      = USER_GID
    USER_NAME                     = USER_NAME
    OLLAMA_MODEL_NAME             = OLLAMA_MODEL_NAME
  }
  secret     = []
  cache_from = ["type=gha"]
  cache_to   = ["type=gha,mode=max"]
  pull       = true
  push       = false
  load       = true
  provenance = false
}
