FROM elixir:1.12-alpine AS builder

ARG BUILD_ENV=prod
ARG BUILD_REL=kubernetex

# Add sources
COPY . /workspace/
WORKDIR /workspace

ENV MIX_ENV=${BUILD_ENV}

RUN mix local.hex --force && mix local.rebar --force && mix deps.get && mix compile && mix test --cover && mix release

FROM alpine:latest AS runner

ARG BUILD_ENV=prod
ARG BUILD_REL=kubernetex

# Install system dependencies
RUN apk add --no-cache openssl ncurses-libs libgcc libstdc++

# Install release
COPY --from=builder /workspace/_build/${BUILD_ENV}/rel/${BUILD_REL} /opt/kubernetex

## Configure environment

# We want a FQDN in the nodename
ENV RELEASE_DISTRIBUTION="name"

# This value should be overriden at runtime
ENV RELEASE_IP="127.0.0.1"

# This will be the basename of our node
ENV RELEASE_NAME="${BUILD_REL}"

# This will be the full nodename
ENV RELEASE_NODE="${RELEASE_NAME}@${RELEASE_IP}"

# If empty, the default cookie generated by `mix release` will be used
# OVERRIDE IT!!
ENV RELEASE_COOKIE=""

ENTRYPOINT ["/opt/kubernetex/bin/kubernetex"]
CMD ["start"]