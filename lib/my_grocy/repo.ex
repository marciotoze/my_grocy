defmodule MyGrocy.Repo do
  use Ecto.Repo,
    otp_app: :my_grocy,
    adapter: Ecto.Adapters.Postgres
end
