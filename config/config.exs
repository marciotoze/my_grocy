# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :my_grocy, Oban,
  engine: Oban.Engines.Basic,
  notifier: Oban.Notifiers.Postgres,
  queues: [default: 10],
  repo: MyGrocy.Repo

config :my_grocy,
  ecto_repos: [MyGrocy.Repo],
  generators: [timestamp_type: :utc_datetime, binary_id: true]

# Configures the endpoint
config :my_grocy, MyGrocyWeb.Endpoint,
  url: [host: "localhost"],
  check_origin: false,
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: MyGrocyWeb.ErrorHTML, json: MyGrocyWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: MyGrocy.PubSub,
  live_view: [signing_salt: "09g0wzV8"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  my_grocy: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :tesla, adapter: Tesla.Adapter.Mint

config :my_grocy, :google_api_key, System.get_env("GOOGLE_API_KEY")
config :my_grocy, :google_cse_id, System.get_env("GOOGLE_CSE_ID")
config :my_grocy, :openai_api_key, System.get_env("OPENAI_API_KEY")

# Redis configuration
config :my_grocy, :redis,
  host: System.get_env("REDIS_HOST", "localhost"),
  port: String.to_integer(System.get_env("REDIS_PORT", "6379"))

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
