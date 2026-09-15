# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

ARG B19_CRYSTAL_BASE_IMAGE=registry.invalid/b19/crystal:latest
ARG B19_UBUNTU_BASE_IMAGE=registry.invalid/b19/ubuntu/resolute:latest
ARG B19_UBUNTU_SERIES=resolute

FROM ${B19_CRYSTAL_BASE_IMAGE} AS ignorelint-builder

ARG B19_COLOR
ARG B19_FETCH_DOCKER_CACHE
ARG B19_FETCH_LOCAL_CACHE
ARG B19_OFFGRID_MODE
ARG B19_VERBOSITY
ARG LANG=""
ARG M6E_AI=N
ARG M6E_APT_CACHE_HOST=""
ARG M6E_APT_CACHE_PORT=""
ARG M6E_BUILD_DEBUG=""
ARG M6E_NAMESPACE
ARG M6E_NEAR_CACHE_HOST=""
ARG M6E_PROJECT
ARG M6E_VERSION
ARG TARGETARCH

WORKDIR ${B19_HOME}

COPY --chown=${B19_UID}:${B19_GID} .container/compile-crystal/ /

COPY --chown=${B19_UID}:${B19_GID} shard.yml  ./
COPY --chown=${B19_UID}:${B19_GID} src/       ./src/

USER 0

RUN --mount=type=bind,from=fetch,source=.,target=/fetch                                           \
    --mount=type=cache,target=${B19_DOWNLOAD_PATH},sharing=shared                                 \
    --mount=type=cache,id=apt-cache-${B19_UBUNTU_SERIES}-${TARGETARCH},target=/var/cache/apt,sharing=shared     \
    --mount=type=cache,id=apt-lists-${B19_UBUNTU_SERIES}-${TARGETARCH},target=/var/lib/apt,sharing=shared       \
    --mount=type=cache,target=${SHARDS_CACHE_PATH},sharing=locked                                 \
    --mount=type=tmpfs,target=${B19_TEMP_PATH}                                                    \
    build-stage compile-crystal

# hadolint ignore=DL3066 # B19_UID comes from the root
USER ${B19_UID}

FROM ${B19_UBUNTU_BASE_IMAGE} AS ignorelint

ARG B19_COLOR
ARG B19_FETCH_DOCKER_CACHE
ARG B19_FETCH_LOCAL_CACHE
ARG B19_OFFGRID_MODE
ARG B19_VERBOSITY
ARG LANG=""
ARG M6E_AI=N
ARG M6E_APT_CACHE_HOST=""
ARG M6E_APT_CACHE_PORT=""
ARG M6E_BUILD_DEBUG=""
ARG M6E_NAMESPACE
ARG M6E_NEAR_CACHE_HOST=""
ARG M6E_PROJECT
ARG M6E_VERSION
ARG TARGETARCH

COPY --chown=${B19_UID}:${B19_GID} .container/base/ /
COPY --from=ignorelint-builder /export /

USER 0

WORKDIR ${B19_HOME}

RUN --mount=type=bind,from=fetch,source=.,target=/fetch                                           \
    --mount=type=cache,target=${B19_DOWNLOAD_PATH},sharing=shared                                 \
    --mount=type=cache,id=apt-cache-${B19_UBUNTU_SERIES}-${TARGETARCH},target=/var/cache/apt,sharing=shared     \
    --mount=type=cache,id=apt-lists-${B19_UBUNTU_SERIES}-${TARGETARCH},target=/var/lib/apt,sharing=shared       \
    --mount=type=tmpfs,target=${B19_TEMP_PATH}                                                    \
    build-stage base

# hadolint ignore=DL3066 # B19_UID comes from the root
USER ${B19_UID}

COPY --chown=${B19_UID}:${B19_GID} .container/user/ /

RUN --mount=type=bind,from=fetch,source=.,target=/fetch                                             \
    --mount=type=cache,target=${B19_DOWNLOAD_PATH},sharing=shared,uid=${B19_UID},gid=${B19_GID}     \
    --mount=type=tmpfs,target=${B19_TEMP_PATH}                                                      \
    build-stage user

# ENTRYPOINT ["entrypoint.d"] is inherited
# HEALTHCHECK CMD ["healthcheck.d"] is inherited
# CMD ["sleep", "infinity"]
