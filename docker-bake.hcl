variable "REGISTRY" {
  default = "123456789012.dkr.ecr.us-east-1.amazonaws.com"
}

variable "TAG" {
  default = "latest"
}

variable "PYTHON_VERSION" {
  default = "3.13"
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

variable "MODEL_GGUF_URL" {
  default = "https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q8_0.gguf"
}

group "default" {
  targets = ["llama-cpp-server"]
}

target "llama-cpp-server" {
  tags       = ["${REGISTRY}/llama-cpp-server:${TAG}"]
  context    = "./src"
  dockerfile = "Dockerfile"
  target     = "app"
  platforms  = ["linux/arm64"]
  args = {
    PYTHON_VERSION = PYTHON_VERSION
    USER_UID       = USER_UID
    USER_GID       = USER_GID
    USER_NAME      = USER_NAME
    MODEL_GGUF_URL = MODEL_GGUF_URL
  }
  cache_from = ["type=gha"]
  cache_to   = ["type=gha,mode=max"]
  pull       = true
  push       = false
  load       = true
  provenance = false
}
