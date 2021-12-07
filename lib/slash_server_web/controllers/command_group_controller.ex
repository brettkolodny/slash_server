defmodule SlashServerWeb.CommandGroupController do
  use SlashServerWeb, :controller

  def show(conn, _params) do
    case SlashServer.Api.read(SlashServer.CommandGroup) do
      {:ok, commands} ->
        command_names = Enum.map(commands, fn c -> Map.get(c, :name) end)
        render(conn, "show.html", names: command_names)

      _ ->
        render(conn, "show.html", names: [])
    end
  end

  def new(conn, _params) do
    render(conn, "new.html", name: nil, description: nil)
  end

  def edit(conn, %{"name" => name}) do
    if name != nil do
      case SlashServer.Api.get(SlashServer.CommandGroup, name: name) do
        {:ok, res} ->
          %{name: name, description: description} = res

          conn
          |> assign(:edit, true)
          |> render("new.html",
            name: name,
            description: description
          )

        _ ->
          render(conn, "new.html", name: nil, description: nil)
      end
    else
      render(conn, "new.html", name: nil, description: nil)
    end
  end

  def create_or_update(conn, params) do
    command_data = Map.get(params, "command")
    %{"name" => name, "description" => desc} = command_data

    res =
      case SlashServer.Api.get(SlashServer.CommandGroup, name: name) do
        {:ok, res} ->
          Ash.Changeset.for_update(res, :update, command_data)
          |> SlashServer.Api.update()

        _ ->
          Ash.Changeset.for_create(SlashServer.CommandGroup, :create, command_data)
          |> SlashServer.Api.create()
      end

    case res do
      {:error, _command} ->
        conn
        |> put_flash(:error, "Invalid entry")
        |> render("new.html", name: name, description: desc)

      _ ->
        # SlashServer.Discord.create_command(name, desc)
        redirect(conn, to: Routes.command_group_path(conn, :show))
    end
  end

  def delete(conn, %{"name" => name}) do
    case SlashServer.Api.get(SlashServer.CommandGroup, name: name) do
      {:ok, res} ->
        case SlashServer.Discord.delete_command(name) do
          :ok ->
            Ash.Changeset.for_destroy(res, :destroy)
            |> SlashServer.Api.destroy()

            redirect(conn, to: Routes.command_group_path(conn, :show))

          :error ->
            conn
            |> put_flash(:error, "Could not delete command")
            |> redirect(to: Routes.command_group_path(conn, :show))
        end

      _ ->
        conn
        |> put_flash(:error, "Could not delete command")
        |> redirect(to: Routes.command_group_path(conn, :show))
    end
  end
end
