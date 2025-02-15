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
      mkdir -p /opt/ollama \
      && curl -SL https://api.github.com/repos/ollama/ollama/releases/latest \
        | grep '"tag_name":' \
        | cut -d'"' -f4 \
        | xargs -I{} -t \
          curl -SL -o /tmp/ollama-linux-arm64.tgz \
            https://github.com/ollama/ollama/releases/download/{}/ollama-linux-arm64.tgz \
      && tar -xvf /tmp/ollama-linux-arm64.tgz -C /opt/ollama --remove-files


FROM public.ecr.aws/awsguru/aws-lambda-adapter:${AWS_LAMBDA_ADAPTER_VERSION} AS aws-lambda-adapter


FROM public.ecr.aws/lambda/provided:${AWS_LAMBDA_PROVIDED_IMAGE_TAG} AS app

ARG USER_UID=1001
ARG USER_GID=1001
ARG USER_NAME=lambda
ARG OLLAMA_MODEL_NAME=llama3.2:1b

COPY --from=builder /opt/ollama /opt/ollama
COPY --from=aws-lambda-adapter /lambda-adapter /opt/extensions/lambda-adapter

ENV OLLAMA_HOST=0.0.0.0:11434
ENV PATH=/opt/ollama/bin:${PATH}

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

RUN \
      --mount=type=bind,source=.,target=/mnt/host \
      cp -a /mnt/host/ollama_pull.sh /usr/local/bin/

USER "${USER_NAME}"

RUN \
      /usr/local/bin/ollama_pull.sh "${OLLAMA_MODEL_NAME}"

EXPOSE 11434

HEALTHCHECK --interval=5s --timeout=3s --retries=3 \
  CMD curl --fail http://localhost:11434/ || exit 1

ENTRYPOINT ["/opt/ollama/bin/ollama"]
CMD ["serve"]
