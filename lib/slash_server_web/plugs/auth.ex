defmodule SlashServerWeb.Plugs.Auth do
  import Plug.Conn
  alias SlashServerWeb.Router.Helpers, as: Routes

  @session_timeout 60

  def init(default), do: default

  # %Plug.Conn{params: %{"session_start" => start, "auth_msg" => msg}}
  def call(conn, _default) do
    case get_session(conn, :start) do
      nil ->
        conn
        |> clear_session()
        |> Phoenix.Controller.redirect(to: Routes.auth_path(conn, :show))
        |> Plug.Conn.halt()

      start ->
        diff =
          start
          |> Time.from_iso8601!()
          |> Time.diff(Time.utc_now())
          |> abs()

        IO.inspect(diff)

        if diff > @session_timeout do
          conn
          |> clear_session()
          |> Phoenix.Controller.redirect(to: Routes.auth_path(conn, :show))
          |> Plug.Conn.halt()
        else
          conn
        end
    end
  end
end
