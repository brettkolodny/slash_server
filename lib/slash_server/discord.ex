defmodule SlashServer.Discord do
  @endpoint "https://discord.com/api/v9/applications/#{Application.get_env(:slash_server, :app_id)}/guilds/#{Application.get_env(:slash_server, :guild_id)}/commands"

  defp get_all_commands() do
    headers = [Authorization: "Bot #{Application.get_env(:slash_server, :app_secret)}"]

    case HTTPoison.get(@endpoint, headers) do
      {:ok, %HTTPoison.Response{body: body}} ->
        case Jason.decode(body) do
          {:ok, commands} ->
            {:ok, commands}

          _ ->
            :error
        end

      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect(reason)
        :error
    end
  end

  defp get_command_id(name) do
    case get_all_commands() do
      {:ok, commands} ->
        id =
          commands
          |> Enum.find(%{}, fn c -> Map.get(c, "name") == name end)
          |> Map.get("id")

        {:ok, id}

      :error ->
        :error
    end
  end

  def create_command(name, desc, commands \\ []) do
    command_options = Enum.map(commands, fn c -> %{ type: 1, name: c.name, description: c.description} end)

    headers = [
      Authorization: "Bot #{Application.get_env(:slash_server, :app_secret)}",
      "Content-Type": "application/json"
    ]

    body = Jason.encode!(%{name: name, description: desc, options: command_options})

    case HTTPoison.post(@endpoint, body, headers) do
      {:ok, %HTTPoison.Response{status_code: code, body: _body}} ->
        IO.inspect(code)
        :ok

      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect(reason)
        :error
    end
  end

  def delete_all_commands() do
    case get_all_commands() do
      {:ok, commands} ->
        for command <- commands do
          if command != nil do
            command
            |> Map.get("id")
            |> delete_command_by_id()
          end
        end
    end
  end

  def delete_command_by_id(nil), do: :ok

  def delete_command_by_id(id) do
    headers = [Authorization: "Bot #{Application.get_env(:slash_server, :app_secret)}"]

    case HTTPoison.delete(
           "#{@endpoint}/#{id}",
           headers
         ) do
      {:ok, _} ->
        :ok

      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect(reason)
        :error
    end
  end

  def delete_command(name) do
    case get_command_id(name) do
      {:ok, nil} ->
        :ok

      {:ok, id} ->
        delete_command_by_id(id)

      :error ->
        :error
    end
  end
end
