FROM elixir:1.16-alpine

# Instala dependências do sistema
RUN apk add --no-cache build-base git npm nodejs postgresql-dev

# Define variáveis
ENV MIX_ENV=prod \
    LANG=C.UTF-8 \
    PORT=4000

WORKDIR /app

# Copia arquivos mix
COPY mix.exs mix.lock ./
COPY config config

# Instala dependências Elixir
RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get --only prod && \
    mix deps.compile

# Copia o restante do código
COPY . .

# Gera assets e digests
WORKDIR /app/assets
RUN npm install

WORKDIR /app
RUN mix assets.deploy

# Compila o app (sem release)
RUN mix compile

# Expõe a porta padrão do Phoenix
EXPOSE 4000

# Comando padrão
CMD ["mix", "phx.server"]
