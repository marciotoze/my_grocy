defmodule MyGrocy.ProductsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `MyGrocy.Products` context.
  """

  @doc """
  Generate a product.
  """
  def product_fixture(attrs \\ %{}) do
    {:ok, product} =
      attrs
      |> Enum.into(%{
        barcodes: %{},
        min_quantity: 42,
        name: "some name",
        quantity: 42
      })
      |> MyGrocy.Products.create_product()

    product
  end
end
