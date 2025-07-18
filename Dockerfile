FROM elixir:1.16-alpine AS base
ENV MIX_ENV=prod PORT=80

RUN apk add --update --no-cache \
    bash \
    curl \
    git \
    nodejs \
    npm \
    build-base \
    tzdata

WORKDIR /app
COPY . /app

RUN mix do local.hex --force, local.rebar --force, deps.get

# BUILD
FROM base AS builder

RUN mix deps.compile

RUN mix compile --warnings-as-errors
RUN mix esbuild my_grocy --minify
RUN mix phx.digest
RUN mix release

# RELEASE
FROM alpine AS release
ENV MIX_ENV=prod PORT=80

RUN apk add --update --no-cache \
    ncurses-libs \
    libstdc++ \
    openssh \
    curl \
    tzdata

WORKDIR /app

COPY --from=builder /app/_build/prod/rel/my_grocy /app/
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/app/entrypoint.sh"]
