defmodule MyGrocy.Services.ProductService do
  @moduledoc """
  Service for managing product operations including EAN lookup and creation
  """

  require Logger
  alias MyGrocy.Products
  alias MyGrocy.Clients.{GoogleClient, OpenAIClient}

  @categories [
    "alimento",
    "bebida",
    "limpeza",
    "higiene",
    "utilidade",
    "outro"
  ]

  def add_product_by_ean(ean) do
    Logger.debug("Adding product by EAN: #{ean}")

    case Products.get_by_barcode(ean) do
      nil ->
        Logger.debug("No product found by barcode #{ean}, fetching product name from Google API")

        with {:ok, names} <- fetch_product_name(ean),
             {:ok, %{name: simple_name, category: category}} <-
               OpenAIClient.simplify_and_categorize(names) do
          Logger.debug(
            "Fetched names: #{inspect(names)}; Simplified name: #{simple_name}, category: #{category}"
          )

          case Products.get_by_name(simple_name) do
            nil ->
              attrs = %{
                name: simple_name,
                quantity: 1,
                min_quantity: 0,
                barcodes: [ean],
                category: category
              }

              Logger.debug("Creating new product with attrs: #{inspect(attrs)}")

              case Products.create_product(attrs) do
                {:ok, _product} ->
                  Logger.debug("Product created successfully for EAN: #{ean}")
                  {:ok, "Product created with EAN: #{ean}"}

                {:error, changeset} ->
                  Logger.error("Failed to create product: #{inspect(changeset.errors)}")
                  {:error, "Failed to create product: #{inspect(changeset.errors)}"}
              end

            product ->
              Logger.debug(
                "Product found by name: #{product.name}, updating quantity and barcodes"
              )

              new_barcodes =
                if ean in product.barcodes, do: product.barcodes, else: [ean | product.barcodes]

              case Products.update_product(product, %{
                     quantity: product.quantity + 1,
                     barcodes: new_barcodes
                   }) do
                {:ok, _updated_product} ->
                  Logger.debug("Product updated by name and EAN added: #{ean}")
                  {:ok, "Product updated by name and EAN added: #{ean}"}

                {:error, changeset} ->
                  Logger.error("Failed to update product: #{inspect(changeset.errors)}")
                  {:error, "Failed to update product: #{inspect(changeset.errors)}"}
              end
          end
        else
          {:error, reason} ->
            Logger.error(
              "Failed to fetch or simplify product name for EAN #{ean}: #{inspect(reason)}"
            )

            {:error, reason}
        end

      product ->
        Logger.debug("Product found by barcode #{ean}, incrementing quantity")

        case Products.update_product(product, %{quantity: product.quantity + 1}) do
          {:ok, _updated_product} ->
            Logger.debug("Product quantity updated successfully for EAN: #{ean}")
            {:ok, "Product quantity updated successfully"}

          {:error, changeset} ->
            Logger.error("Failed to update product: #{inspect(changeset.errors)}")
            {:error, "Failed to update product: #{inspect(changeset.errors)}"}
        end
    end
  end

  def remove_product_by_ean(ean) do
    Logger.debug("Removing product by EAN: #{ean}")

    case Products.get_by_barcode(ean) do
      nil ->
        Logger.debug("Product not found for EAN: #{ean}")
        {:ok, "Product not found for EAN: #{ean}"}

      product ->
        Logger.debug("Product found for EAN: #{ean}, decrementing quantity")

        case Products.update_product(product, %{quantity: product.quantity - 1}) do
          {:ok, _updated_product} ->
            Logger.debug("Product quantity updated successfully for EAN: #{ean}")
            {:ok, "Product quantity updated successfully"}

          {:error, changeset} ->
            Logger.error("Failed to update product: #{inspect(changeset.errors)}")
            {:error, "Failed to update product: #{inspect(changeset.errors)}"}
        end
    end
  end

  defp fetch_product_name(ean) do
    Logger.debug("Fetching product name from Google API for EAN: #{ean}")

    case GoogleClient.search_names_by_ean(ean) do
      {:ok, names} ->
        Logger.debug("Google API returned names: #{inspect(names)}")
        {:ok, names}

      {:error, reason} ->
        Logger.error("Google API error for EAN #{ean}: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
