defmodule MyGrocy.Workers.ProductWorker do
  use Oban.Worker, queue: :default, max_attempts: 3

  require Logger
  alias MyGrocy.Services.ProductService

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"action" => "add", "ean" => ean}}) do
    Logger.debug("Starting 'add' action for EAN: #{ean}")
    ProductService.add_product_by_ean(ean)
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"action" => "remove", "ean" => ean}}) do
    Logger.debug("Starting 'remove' action for EAN: #{ean}")
    ProductService.remove_product_by_ean(ean)
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    Logger.error("Invalid action received in ProductWorker: #{inspect(args)}")
    {:error, "Invalid action: #{inspect(args)}"}
  end
end
