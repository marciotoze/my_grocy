FROM elixir:1.16-alpine AS build

# Instala dependências do sistema
RUN apk add --no-cache build-base git npm nodejs postgresql-dev

# Define variáveis
ENV MIX_ENV=prod \
    LANG=C.UTF-8

WORKDIR /app

# Copia arquivos mix
COPY mix.exs mix.lock ./
COPY config config

# Instala dependências Elixir
RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get --only prod && \
    mix deps.compile

# Copia código restante
COPY . .

# Compila assets se houver (ajuste se não usar tailwind/webpack)
RUN cd assets
RUN mix phx.digest

# Compila o release
RUN mix release

# Stage 2: Runtime
FROM alpine:3.19 AS app

RUN apk add --no-cache libstdc++ openssl ncurses-libs

WORKDIR /app

# Copia release da etapa anterior
COPY --from=build /app/_build/prod/rel/* ./

# Exponha a porta (ajuste se usar outra)
EXPOSE 4000

# Define entrada padrão
CMD ["bin/my_grocy", "start"]
