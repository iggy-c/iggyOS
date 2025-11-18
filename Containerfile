FROM scratch AS ctx
COPY build_files / 

FROM ghcr.io/ublue-os/aurora:stable

RUN --mount=type=bind,from=ctx,source=/ctx,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/install-apps.sh && \
    /ctx/build.sh
