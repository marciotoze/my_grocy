defmodule MyGrocy.Clients.OpenAIClient do
  @moduledoc """
  Tesla client for OpenAI API with Redis cache
  """

  @timeout 30_000

  @categories [
    "alimento",
    "bebida",
    "limpeza",
    "higiene",
    "utilidade",
    "outro"
  ]

  def simplify_and_categorize(names) when is_list(names) do
    names_str =
      names
      |> Enum.with_index(1)
      |> Enum.map(fn {n, i} -> "#{i}) #{n}" end)
      |> Enum.join("\n")

    products_names =
      MyGrocy.Products.list_products()
      |> Enum.map(& &1.name)

    prompt = """
    Dado até 3 nomes de um mesmo produto,
    simplifique para um único nome adequado para uso em um inventário doméstico,
    (sem marca ou quantidade) para que se iguale ao nome de produtos do mesmo tipo, por exemplo:
    "Leite UHT integral" deve ser simplificado para "Leite" e "Leite UHT desnatado" deve ser simplificado para "Leite".
    produtos light, diet, zero, etc. devem ser simplificados para o nome do produto sem a palavra light, diet, zero, etc.
    se o produto for similar a algum dos nomes da lista abaixo, retorne o nome da lista, se não for similar, retorne o nome simplificado:

    #{Enum.join(products_names, ", ")}

    e categorize em uma das opções: #{Enum.join(@categories, ", ")}.
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
        {"Authorization", "Bearer #{openai_api_key()}"},
        {"Content-Type", "application/json"}
      ]

      # Increase timeout to 30 seconds
      opts = [opts: [recv_timeout: @timeout, timeout: @timeout]]

      case Tesla.post(client(), "/chat/completions", body, headers: headers, opts: opts) do
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
          {:error, "OpenAI API error: status #{status} and body #{inspect(error_body)}"}

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

  defp client do
    Tesla.client([
      {Tesla.Middleware.BaseUrl, "https://api.openai.com/v1"},
      {Tesla.Middleware.JSON, engine: Jason},
      {Tesla.Middleware.Logger, log_level: :debug}
    ])
  end

  defp openai_api_key(), do: Application.get_env(:my_grocy, :openai_api_key)
end
