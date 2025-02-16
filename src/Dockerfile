# syntax=docker/dockerfile:1
ARG AWS_LAMBDA_PROVIDED_IMAGE_TAG=al2023
ARG AWS_LAMBDA_ADAPTER_VERSION=0.9.0

FROM public.ecr.aws/lambda/provided:${AWS_LAMBDA_PROVIDED_IMAGE_TAG} AS builder

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

# hadolint ignore=DL3040,DL3041
RUN \
      --mount=type=cache,target=/var/cache/yum,sharing=locked \
      --mount=type=cache,target=/var/cache/dnf,sharing=locked \
      --mount=type=cache,target=/var/lib/yum,sharing=locked \
      --mount=type=cache,target=/var/lib/dnf,sharing=locked \
      dnf -y upgrade \
      && dnf -y install ca-certificates findutils gzip tar

# hadolint ignore=SC2102
RUN \
      curl -SL https://api.github.com/repos/ollama/ollama/releases/latest \
        | grep '"tag_name":' \
        | cut -d'"' -f4 \
        | xargs -I{} -t \
          curl -SL -o /tmp/ollama-linux-arm64.tgz \
            https://github.com/ollama/ollama/releases/download/{}/ollama-linux-arm64.tgz \
      && tar -xvf /tmp/ollama-linux-arm64.tgz -C /usr/local --remove-files


FROM public.ecr.aws/awsguru/aws-lambda-adapter:${AWS_LAMBDA_ADAPTER_VERSION} AS aws-lambda-adapter


FROM public.ecr.aws/lambda/provided:${AWS_LAMBDA_PROVIDED_IMAGE_TAG} AS app

ARG USER_UID=1001
ARG USER_GID=1001
ARG USER_NAME=lambda
ARG OLLAMA_MODEL_NAME=llama3.2:1b

COPY --from=builder /usr/local /usr/local
COPY --from=aws-lambda-adapter /lambda-adapter /opt/extensions/lambda-adapter

ENV PORT=11434
ENV OLLAMA_HOST=0.0.0.0:${PORT}
ENV OLLAMA_MODELS=/opt/ollama

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
      && /sbin/useradd --uid "${USER_UID}" --gid "${USER_GID}" --shell /bin/bash "${USER_NAME}"

RUN \
      --mount=type=bind,source=.,target=/mnt/host \
      cp -a /mnt/host/ollama_pull.sh /usr/local/bin/

RUN \
      mkdir -p "${OLLAMA_MODELS}" \
      && chown -R ${USER_NAME}:${USER_NAME} "${OLLAMA_MODELS}"

USER ${USER_NAME}

RUN \
      /usr/local/bin/ollama_pull.sh "${OLLAMA_MODEL_NAME}"

EXPOSE ${PORT}

HEALTHCHECK --interval=5s --timeout=3s --retries=3 \
  CMD curl --fail "http://localhost:${PORT}/" || exit 1

ENTRYPOINT ["/usr/local/bin/ollama"]
CMD ["serve"]
