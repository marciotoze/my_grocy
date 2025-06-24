defmodule MyGrocyWeb.UserNavigation do
  import Phoenix.LiveView
  import Phoenix.Component

  def on_mount(:default, _params, _session, socket) do
    {:cont,
     socket
     |> attach_hook(:handle, :handle_params, &handle/3)}
  end

  defp handle(_params, uri, socket) do
    %URI{path: path} = URI.parse(uri)

    {:cont, socket |> assign(request_path: path)}
  end
end
