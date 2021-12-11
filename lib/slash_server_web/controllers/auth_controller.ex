defmodule SlashServerWeb.AuthController do
  use SlashServerWeb, :controller

  def show(conn, _params) do
    render(conn, "show.html")
  end

  def login(conn, %{"login" => %{"password" => password}} = params) do
    IO.inspect(params)

    case Application.get_env(:slash_server, :app_password) do
      nil ->
        conn
        |> put_flash(:error, "Error logging in")
        |> redirect(to: Routes.auth_path(conn, :show))

      pass ->
        if pass == password do
          time = Time.utc_now() |> Time.to_string()

          conn
          |> put_session(:start, time)
          |> redirect(to: Routes.command_group_path(conn, :show))
        else
          conn
          |> put_flash(:error, "Invalid password")
          |> redirect(to: Routes.auth_path(conn, :show))
        end
    end
  end
end
