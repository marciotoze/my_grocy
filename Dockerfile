FROM elixir:1.16-alpine

RUN apk add --no-cache build-base npm git sqlite-dev

WORKDIR /app

COPY mix.exs mix.lock ./
COPY config config
RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get

COPY . .

CMD ["mix", "phx.server"]
