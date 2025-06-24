defmodule MyGrocy.Products do
  @moduledoc """
  The Products context.
  """

  import Ecto.Query, warn: false
  alias MyGrocy.Repo

  alias MyGrocy.Products.Product

  @doc """
  Returns the list of products.

  ## Examples

      iex> list_products()
      [%Product{}, ...]

  """
  def list_products do
    from(p in Product,
      order_by: [
        desc: p.min_quantity > p.quantity,
        asc: p.name
      ]
    )
    |> Repo.all()
  end

  def list_last_changed_products(number \\ 10) do
    from(p in Product,
      limit: ^number,
      order_by: [
        desc: p.updated_at
      ]
    )
    |> Repo.all()
  end

  def get_by_barcode(barcode) do
    from(p in Product,
      where: fragment("? @> ?", p.barcodes, ^[barcode])
    )
    |> Repo.one()
  end

  def get_by_name(name) do
    from(p in Product,
      where: p.name == ^name
    )
    |> Repo.one()
  end

  @doc """
  Gets a single product.

  Raises `Ecto.NoResultsError` if the Product does not exist.

  ## Examples

      iex> get_product!(123)
      %Product{}

      iex> get_product!(456)
      ** (Ecto.NoResultsError)

  """
  def get_product!(id), do: Repo.get!(Product, id)

  @doc """
  Creates a product.

  ## Examples

      iex> create_product(%{field: value})
      {:ok, %Product{}}

      iex> create_product(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_product(attrs \\ %{}) do
    %Product{}
    |> Product.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a product.

  ## Examples

      iex> update_product(product, %{field: new_value})
      {:ok, %Product{}}

      iex> update_product(product, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_product(%Product{} = product, attrs) do
    product
    |> Product.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a product.

  ## Examples

      iex> delete_product(product)
      {:ok, %Product{}}

      iex> delete_product(product)
      {:error, %Ecto.Changeset{}}

  """
  def delete_product(%Product{} = product) do
    Repo.delete(product)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking product changes.

  ## Examples

      iex> change_product(product)
      %Ecto.Changeset{data: %Product{}}

  """
  def change_product(%Product{} = product, attrs \\ %{}) do
    Product.changeset(product, attrs)
  end
end
