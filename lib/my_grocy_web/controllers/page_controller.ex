defmodule MyGrocyWeb.PageController do
  use MyGrocyWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
