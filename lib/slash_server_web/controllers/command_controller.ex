defmodule SlashServerWeb.CommandController do
  use SlashServerWeb, :controller

  def show(conn, %{"command_group" => command_group}) do
    case SlashServer.Api.get!(SlashServer.CommandGroup, name: command_group)
         |> SlashServer.Api.load([:commands]) do
      {:ok, %SlashServer.CommandGroup{commands: commands}} ->
        case commands do
          %Ash.NotLoaded{} ->
            render(conn, "show.html", names: [], command_group: command_group)

          _ ->
            # IO.inspect(commands)
            names = Enum.map(commands, fn c -> Map.get(c, :name) end)
            render(conn, "show.html", names: names, command_group: command_group)
        end

      _ ->
        render(conn, "show.html", names: [], command_group: command_group)
    end
  end

  def new(conn, %{"command_group" => command_group}) do
    render(conn, "new.html",
      name: nil,
      description: nil,
      response: nil,
      command_group: command_group
    )
  end

  def edit(conn, %{"name" => name, "command_group" => command_group}) do
    if name != nil do
      case SlashServer.Api.get(SlashServer.CommandGroup, name: name) do
        {:ok, res} ->
          %{name: name, description: desc, response: resp} = res

          conn
          |> assign(:edit, true)
          |> render("new.html",
            name: name,
            description: desc,
            response: resp,
            command_group: command_group
          )

        _ ->
          render(conn, "new.html", name: nil, description: nil, command_group: command_group)
      end
    else
      render(conn, "new.html", name: nil, description: nil, command_group: command_group)
    end
  end

  def create_or_update(conn, %{"command" => command_data, "command_group" => command_group}) do
    %{"name" => name, "description" => desc, "response" => resp} = command_data

    case SlashServer.Api.get!(SlashServer.CommandGroup, name: command_group)
         |> SlashServer.Api.load([:commands]) do
      {:ok, group} ->
        res =
          case SlashServer.Api.get(SlashServer.Command, name: name) do
            {:ok, res} ->
              Ash.Changeset.for_update(res, :update, command_data)
              |> SlashServer.Api.update()

            _ ->
              {:ok, command} =
                Ash.Changeset.for_create(SlashServer.Command, :create, command_data)
                |> SlashServer.Api.create()

              group
              |> SlashServer.Api.load!([:commands])
              |> then(fn group ->
                IO.inspect(group.commands, limit: :infinity)
                group
              end)
              |> Ash.Changeset.for_update(:update)
              |> Ash.Changeset.append_to_relationship(:commands, command)
              |> SlashServer.Api.update()
              # <-- Don't you need a load after the update?
              |> SlashServer.Api.load!([:commands])
              |> then(fn group ->
                IO.inspect(group.commands, limit: :infinity)
                group
              end)
          end

        case res do
          {:error, _command} ->
            conn
            |> put_flash(:error, "Invalid entry")
            |> render("new.html",
              name: name,
              description: desc,
              response: resp,
              command_group: command_group
            )

          _ ->
            # SlashServer.Discord.create_command(name, desc)
            redirect(conn, to: Routes.command_path(conn, :show, command_group))
        end

      _ ->
        conn
        |> put_flash(:error, "Command group does not exist")
        |> render("new.html",
          name: name,
          description: desc,
          response: resp,
          command_group: command_group
        )
    end
  end

  def delete(conn, %{"name" => name, "command_group" => command_group}) do
    case SlashServer.Api.get(SlashServer.Command, name: name) do
      {:ok, res} ->
        case SlashServer.Discord.delete_command(name) do
          :ok ->
            Ash.Changeset.for_destroy(res, :destroy)
            |> SlashServer.Api.destroy()

            redirect(conn, to: Routes.command_path(conn, :show, command_group))

          :error ->
            conn
            |> put_flash(:error, "Could not delete command")
            |> redirect(to: Routes.command_path(conn, :show, command_group))
        end

      _ ->
        conn
        |> put_flash(:error, "Could not delete command")
        |> redirect(to: Routes.command_path(conn, :show, command_group))
    end
  end
end
