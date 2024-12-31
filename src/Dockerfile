# syntax=docker/dockerfile:1
ARG PYTHON_VERSION=3.13
FROM public.ecr.aws/lambda/python:${PYTHON_VERSION} AS base

ARG LLM_URL=https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q8_0.gguf

ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONIOENCODING=UTF-8
ENV PIP_NO_CACHE_DIR=off
ENV PIP_DISABLE_PIP_VERSION_CHECK=on
ENV LLM_PATH=/opt/model/llm.gguf

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

# hadolint ignore=DL3040,DL3041
RUN \
      --mount=type=cache,target=/var/cache/yum,sharing=locked \
      --mount=type=cache,target=/var/cache/dnf,sharing=locked \
      --mount=type=cache,target=/var/lib/yum,sharing=locked \
      --mount=type=cache,target=/var/lib/dnf,sharing=locked \
      dnf -y upgrade \
      && dnf -y install ca-certificates curl

# hadolint ignore=SC2102
RUN \
      --mount=type=cache,target=/root/.cache/pip \
      CMAKE_ARGS="-DCMAKE_CXX_FLAGS='-mcpu=native' -DCMAKE_C_FLAGS='-mcpu=native'" \
      /var/lang/bin/python -m pip install -U \
        aws-lambda-powertools awslambdaric llama-cpp-python[server] pip

RUN \
      mkdir -p /opt/model \
      && curl -SL -o "${LLM_PATH}" "${LLM_URL}"

HEALTHCHECK NONE


FROM base AS app

# ENV LAMBDA_TASK_ROOT=/var/task

EXPOSE 8080

ENTRYPOINT ["/var/lang/bin/python", "-m", "llama_cpp.server"]
CMD ["--model=/opt/model/llm.gguf", "--n_ctx=16192", "--port=8080"]
