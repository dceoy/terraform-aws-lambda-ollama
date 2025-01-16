# syntax=docker/dockerfile:1
ARG PYTHON_VERSION=3.13
ARG AWS_LAMBDA_ADAPTER_VERSION=0.9.0

FROM public.ecr.aws/lambda/python:${PYTHON_VERSION} AS builder

ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONIOENCODING=UTF-8
ENV PIP_NO_CACHE_DIR=off
ENV PIP_DISABLE_PIP_VERSION_CHECK=on

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

# hadolint ignore=DL3040,DL3041
RUN \
      --mount=type=cache,target=/var/cache/yum,sharing=locked \
      --mount=type=cache,target=/var/cache/dnf,sharing=locked \
      --mount=type=cache,target=/var/lib/yum,sharing=locked \
      --mount=type=cache,target=/var/lib/dnf,sharing=locked \
      dnf -y upgrade \
      && dnf -y install g++ gcc

# hadolint ignore=SC2102
RUN \
      --mount=type=cache,target=/root/.cache/pip \
      --mount=type=bind,source=.,target=/mnt/host \
      /var/lang/bin/python -m pip install -U awslambdaric pip \
      && CMAKE_ARGS="-DCMAKE_CXX_FLAGS='-mcpu=native' -DCMAKE_C_FLAGS='-mcpu=native' -DGGML_NATIVE=OFF" \
        /var/lang/bin/python -m pip install -U -r /mnt/host/requirements.txt


FROM public.ecr.aws/awsguru/aws-lambda-adapter:${AWS_LAMBDA_ADAPTER_VERSION} AS aws-lambda-adapter


FROM public.ecr.aws/lambda/python:${PYTHON_VERSION} AS app

ARG USER_UID=1001
ARG USER_GID=1001
ARG USER_NAME=lambda
ARG MODEL_GGUF_URL=https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q8_0.gguf

COPY --from=builder /var/lang /var/lang
COPY --from=aws-lambda-adapter /lambda-adapter /opt/extensions/lambda-adapter

ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONIOENCODING=UTF-8
ENV PIP_NO_CACHE_DIR=off
ENV PIP_DISABLE_PIP_VERSION_CHECK=on
ENV MODEL_GGUF_PATH=/opt/model/llm.gguf

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

# hadolint ignore=DL3040,DL3041
RUN \
      --mount=type=cache,target=/var/cache/yum,sharing=locked \
      --mount=type=cache,target=/var/cache/dnf,sharing=locked \
      --mount=type=cache,target=/var/lib/yum,sharing=locked \
      --mount=type=cache,target=/var/lib/dnf,sharing=locked \
      dnf -y upgrade \
      && dnf -y install libgomp shadow-utils

RUN \
      /sbin/groupadd --gid "${USER_GID}" "${USER_NAME}" \
      && /sbin/useradd --uid "${USER_UID}" --gid "${USER_GID}" --shell /bin/bash --create-home "${USER_NAME}"

# hadolint ignore=DL3040
RUN \
      --mount=type=cache,target=/var/cache/yum,sharing=locked \
      --mount=type=cache,target=/var/cache/dnf,sharing=locked \
      --mount=type=cache,target=/var/lib/yum,sharing=locked \
      --mount=type=cache,target=/var/lib/dnf,sharing=locked \
      dnf -y remove shadow-utils

RUN \
      mkdir -p /opt/model \
      && curl -SL -o "${MODEL_GGUF_PATH}" "${MODEL_GGUF_URL}"

USER "${USER_NAME}"

EXPOSE 8080

HEALTHCHECK --interval=5s --timeout=3s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

ENTRYPOINT ["/var/lang/bin/python", "-m", "llama_cpp.server"]
CMD ["--model=/opt/model/llm.gguf", "--n_ctx=16192", "--port=8080"]
