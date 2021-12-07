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
      case SlashServer.Api.get(SlashServer.Command, name: name) do
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

              SlashServer.Api.load!(group, [:commands])

            _ ->
              {:ok, command} =
                Ash.Changeset.for_create(SlashServer.Command, :create, command_data)
                |> SlashServer.Api.create()

              group
              |> SlashServer.Api.load!([:commands])
              |> Ash.Changeset.for_update(:update)
              |> Ash.Changeset.replace_relationship(:commands, [command | group.commands])
              |> SlashServer.Api.update()
              |> SlashServer.Api.load!([:commands])
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
            IO.inspect(res)

            commands =
              Enum.map(res.commands, fn c -> %{name: c.name, description: c.description} end)

            SlashServer.Discord.create_command(group.name, group.description, commands)
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
        case Ash.Changeset.for_destroy(res, :destroy)
             |> SlashServer.Api.destroy()
             |> IO.inspect() do
          :ok ->
            %{name: name, description: desc, commands: commands} =
              SlashServer.CommandGroup
              |> SlashServer.Api.get!(name: command_group)
              |> SlashServer.Api.load!([:commands])

            SlashServer.Discord.create_command(name, desc, commands)
            redirect(conn, to: Routes.command_path(conn, :show, command_group))

          _ ->
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
