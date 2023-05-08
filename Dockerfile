# syntax = docker/dockerfile:1.4
FROM nixos/nix:latest AS builder

WORKDIR /tmp/build
RUN mkdir /tmp/nix-store-closure
COPY . /tmp/build

RUN --mount=type=cache,target=/nix,from=nixos/nix:latest,source=/nix --mount=type=cache,target=/root/.cache <<EOF 
  nix \
    --extra-experimental-features "nix-command flakes" \
    --extra-substituters "http://host.docker.internal?priority=10" \
    --option filter-syscalls false \
    --show-trace \
    --log-format raw \
    build .
  cp -R $(nix-store -qR result/) /tmp/nix-store-closure
  cp -R $(readlink /tmp/build/result) /tmp/result
EOF

FROM scratch

WORKDIR /app

COPY --from=builder /tmp/nix-store-closure /nix/store
COPY --from=builder /tmp/result/ /app/
ENTRYPOINT ["/app/bin/entrypoint"]
