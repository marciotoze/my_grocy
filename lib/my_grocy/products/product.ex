defmodule MyGrocy.Products.Product do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "products" do
    field :name, :string
    field :quantity, :integer
    field :min_quantity, :integer
    field :barcodes, :map

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(product, attrs) do
    product
    |> cast(attrs, [:name, :quantity, :min_quantity, :barcodes])
    |> validate_required([:name, :quantity, :min_quantity])
  end
end
