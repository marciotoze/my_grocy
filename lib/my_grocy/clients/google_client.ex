defmodule MyGrocy.Clients.GoogleClient do
  @moduledoc """
  Tesla client for Google Custom Search API with Redis cache
  """

  use Tesla

  @google_api_key Application.get_env(:my_grocy, :google_api_key)
  @google_cse_id Application.get_env(:my_grocy, :google_cse_id)

  plug Tesla.Middleware.BaseUrl, "https://www.googleapis.com/customsearch/v1"
  plug Tesla.Middleware.JSON
  plug Tesla.Middleware.Logger

  def search_names_by_ean(ean) do
    cache_key = "google_search:#{ean}"

    MyGrocy.Cache.get_or_set(cache_key, fn ->
      params = [
        key: @google_api_key,
        cx: @google_cse_id,
        q: ean
      ]

      case get("", query: params) do
        {:ok, %Tesla.Env{status: 200, body: body}} ->
          items = body["items"] || []

          names =
            items
            |> Enum.map(& &1["title"])
            |> Enum.filter(& &1)
            |> Enum.take(3)

          if names != [] do
            {:ok, names}
          else
            {:error, "No product names found for EAN: #{ean}"}
          end

        {:ok, %Tesla.Env{status: status}} ->
          {:error, "Google API error: status #{status}"}

        {:error, reason} ->
          {:error, "Google API request failed: #{inspect(reason)}"}
      end
    end)
  end
end
