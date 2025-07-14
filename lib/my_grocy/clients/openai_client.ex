defmodule MyGrocy.Clients.OpenAIClient do
  @moduledoc """
  Tesla client for OpenAI API with Redis cache
  """

  use Tesla

  @openai_api_key Application.get_env(:my_grocy, :openai_api_key)

  plug Tesla.Middleware.BaseUrl, "https://api.openai.com/v1"
  plug Tesla.Middleware.JSON
  plug Tesla.Middleware.Logger

  def simplify_and_categorize(names) when is_list(names) do
    names_str =
      names
      |> Enum.with_index(1)
      |> Enum.map(fn {n, i} -> "#{i}) #{n}" end)
      |> Enum.join("\n")

    prompt = """
    Dado até 3 nomes de um mesmo produto,
    simplifique para um único nome adequado para uso em um inventário doméstico
    (sem marca ou quantidade)
    e categorize em uma das opções: alimento, bebida, limpeza, higiene, utilidade, outro.
    Responda apenas em JSON (não array): {"name":"nome_simplificado", "category":"categoria"}.
    Nomes:
    #{names_str}
    """

    messages = [
      %{"role" => "user", "content" => prompt}
    ]

    cache_key = "openai_simplify:#{hash_messages(messages)}"

    MyGrocy.Cache.get_or_set(cache_key, fn ->
      max_tokens = 150
      temperature = 0.1
      model = "gpt-3.5-turbo"

      body = %{
        "model" => model,
        "messages" => messages,
        "max_tokens" => max_tokens,
        "temperature" => temperature
      }

      headers = [
        {"Authorization", "Bearer #{@openai_api_key}"}
      ]

      case post("/chat/completions", body, headers: headers) do
        {:ok,
         %Tesla.Env{
           status: 200,
           body: %{"choices" => [%{"message" => %{"content" => content}} | _]}
         }} ->
          case Jason.decode(content) do
            {:ok, %{"name" => simple_name, "category" => category}} ->
              {:ok, %{name: simple_name, category: category}}

            {:error, decode_error} ->
              {:error, "OpenAI response parse error: #{inspect(decode_error)}"}

            _ ->
              {:error, "OpenAI response parse error: #{inspect(content)}"}
          end

        {:ok, %Tesla.Env{status: status, body: error_body}} ->
          {:error, "OpenAI API error: status #{status}"}

        {:error, reason} ->
          {:error, "OpenAI API request failed: #{inspect(reason)}"}
      end
    end)
  end

  defp hash_messages(messages) do
    :crypto.hash(:sha256, Jason.encode!(messages))
    |> Base.encode16(case: :lower)
    |> binary_part(0, 16)
  end
end
