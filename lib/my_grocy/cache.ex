defmodule MyGrocy.Cache do
  @moduledoc """
  Redis cache for API responses with 24h TTL
  """

  require Logger

  # 24 hours in seconds
  @cache_ttl 24 * 60 * 60

  def get(key) do
    case Redix.command(MyGrocy.Redis, ["GET", cache_key(key)]) do
      {:ok, nil} ->
        Logger.debug("Cache miss for key: #{key}")
        nil

      {:ok, value} ->
        Logger.debug("Cache hit for key: #{key}")
        Jason.decode(value)

      {:error, reason} ->
        Logger.error("Redis error getting key #{key}: #{inspect(reason)}")
        nil
    end
  end

  def set(key, value) do
    encoded_value = Jason.encode!(value)

    case Redix.command(MyGrocy.Redis, ["SETEX", cache_key(key), @cache_ttl, encoded_value]) do
      {:ok, "OK"} ->
        Logger.debug("Cached value for key: #{key}")
        {:ok, value}

      {:error, reason} ->
        Logger.error("Redis error setting key #{key}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def get_or_set(key, fallback_fn) do
    case get(key) do
      {:ok, cached_value} ->
        {:ok, cached_value}

      nil ->
        case fallback_fn.() do
          {:ok, value} = result ->
            set(key, value)
            result

          error ->
            error
        end
    end
  end

  defp cache_key(key) do
    "my_grocy:cache:#{key}"
  end
end
