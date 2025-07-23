defmodule MyGrocyWeb.ProductController do
  use MyGrocyWeb, :controller

  alias MyGrocy.Services.ProductService

  def add(conn, %{"ean" => ean}) do
    with {:ok, _} <- ProductService.add_product_by_ean(ean) do
      conn
      |> put_status(:ok)
      |> json(%{"message" => "Product add job queued"})
    else
      {:error, message} ->
        conn
        |> put_status(:bad_request)
        |> json(%{"message" => message})
    end
  end

  def remove(conn, %{"ean" => ean}) do
    with {:ok, _} <- ProductService.remove_product_by_ean(ean) do
      conn
      |> put_status(:ok)
      |> json(%{"message" => "Product remove job queued"})
    else
      {:error, message} ->
        conn
        |> put_status(:bad_request)
        |> json(%{"message" => message})
    end
  end
end
