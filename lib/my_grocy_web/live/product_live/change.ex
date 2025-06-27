defmodule MyGrocyWeb.ProductLive.Change do
  use MyGrocyWeb, :live_view

  alias MyGrocy.Products

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> stream(:products, Products.list_last_changed_products())
     |> assign(:show_modal, false)}
  end

  @impl true
  def handle_params(_params, _uri, socket), do: {:noreply, socket}

  @impl true
  def handle_event(
        "barcode_scanned",
        %{
          "barcode" => barcode,
          "action" => action,
          "quantity" => quantity
        },
        socket
      ) do
    case Products.get_by_barcode(barcode) do
      nil ->
        # nenhum produto com o barcode → pede nome
        products = Products.list_products()

        {:noreply,
         socket
         |> assign(:pending_barcode, barcode)
         |> assign(:pending_quantity, quantity)
         |> stream(:products, Products.list_last_changed_products())
         |> assign(:autocomplete_name, Enum.map(products, & &1.name))
         |> assign(:show_modal, true)}

      product ->
        # produto encontrado → incrementa
        new_qty =
          case action do
            "add" -> product.quantity + String.to_integer(quantity)
            "remove" -> max(product.quantity - String.to_integer(quantity), 0)
            _ -> product.quantity
          end

        {:ok, _} = Products.update_product(product, %{quantity: new_qty})

        {:noreply,
         socket
         |> stream(:products, Products.list_last_changed_products())
         |> push_event("toast", %{
           type: "success",
           message: "Produto atualizado com sucesso"
         })}
    end
  end

  def handle_event("submit_new_product", %{"name" => name}, socket) do
    barcode = socket.assigns.pending_barcode
    quantity = socket.assigns.pending_quantity

    product = Products.get_by_name(name)

    cond do
      product ->
        Products.update_product(product, %{
          barcodes: [barcode | product.barcodes],
          quantity: product.quantity + String.to_integer(quantity)
        })

      true ->
        Products.create_product(%{
          name: name,
          quantity: String.to_integer(quantity),
          barcodes: [barcode]
        })
    end

    {:noreply,
     socket
     |> assign(:show_modal, false)
     |> assign(:pending_barcode, nil)
     |> stream(:products, Products.list_last_changed_products())
     |> assign(:product_name, "")}
  end

  def time_ago(from, now \\ DateTime.utc_now()) do
    seconds = DateTime.diff(now, from)

    cond do
      seconds < 60 ->
        "agora mesmo"

      seconds < 3600 ->
        "#{div(seconds, 60)} minutos atrás"

      seconds < 86_400 ->
        "#{div(seconds, 3600)} horas atrás"

      true ->
        "#{div(seconds, 86_400)} dias atrás"
    end
  end
end
