defmodule MyGrocyWeb.ProductController do
  use MyGrocyWeb, :controller

  alias MyGrocy.Workers.ProductWorker

  def add(conn, %{"ean" => ean}) do
    %{ean: ean, action: "add"}
    |> ProductWorker.new()
    |> Oban.insert()

    conn
    |> put_status(:ok)
    |> json(%{"message" => "Product add job queued"})
  end

  def remove(conn, %{"ean" => ean}) do
    %{ean: ean, action: "remove"}
    |> ProductWorker.new()
    |> Oban.insert()

    conn
    |> put_status(:ok)
    |> json(%{"message" => "Product remove job queued"})
  end
end
