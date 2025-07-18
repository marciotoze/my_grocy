defmodule MyGrocyWeb.Router do
  use MyGrocyWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MyGrocyWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MyGrocyWeb do
    pipe_through :browser

    live_session :default, on_mount: [MyGrocyWeb.UserNavigation] do
      live "/products", ProductLive.Index, :index
      live "/products/:id/edit", ProductLive.Index, :edit

      live "/", ProductLive.Change, :scan
    end
  end

  scope "/api", MyGrocyWeb do
    pipe_through :api

    post "/products/add/:ean", ProductController, :add
    post "/products/remove/:ean", ProductController, :remove
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:my_grocy, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: MyGrocyWeb.Telemetry
    end
  end
end
