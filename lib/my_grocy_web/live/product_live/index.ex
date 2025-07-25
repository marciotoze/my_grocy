defmodule MyGrocyWeb.ProductLive.Index do
  use MyGrocyWeb, :live_view

  alias MyGrocy.Products

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :products, Products.list_products())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Product")
    |> assign(:product, Products.get_product!(id))
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Products")
    |> assign(:product, nil)
  end

  @impl true
  def handle_info({MyGrocyWeb.ProductLive.FormComponent, {:saved, product}}, socket) do
    {:noreply,
     socket
     |> stream_insert(:products, product)
     |> push_navigate(to: ~p"/products")}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    product = Products.get_product!(id)
    {:ok, _} = Products.delete_product(product)

    {:noreply, stream_delete(socket, :products, product)}
  end
end
