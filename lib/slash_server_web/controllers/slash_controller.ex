defmodule SlashServerWeb.SlashController do
  use SlashServerWeb, :controller

  @public_key "44ea0b11f60503fe9fffe01d745f0b10ad8432b63de39b3ef1ee48a736a93af3"
  @embed_color 0xFF4C3B

  defp construct_response(name, desc, resp) do
    embed = %{
      title: desc,
      description: resp,
      type: "rich",
      footer: %{text: name},
      color: @embed_color
    }

    %{
      type: 4,
      data: %{
        tts: false,
        embeds: [embed]
      }
    }
  end

  defp valid_request?(conn, params) do
    body = Jason.encode!(params)

    x_sig =
      get_req_header(conn, "x-signature-ed25519")
      |> List.first()
      |> Base.decode16!(case: :lower)

    msg =
      get_req_header(conn, "x-signature-timestamp")
      |> List.first()
      |> Kernel.<>(body)

    public_key = @public_key |> Base.decode16!(case: :lower)

    if Kcl.valid_signature?(x_sig, msg, public_key) do
      true
    else
      false
    end
  end

  defp respond_to_slash(conn, %{"data" => %{"name" => name}}) do
    case SlashServer.Api.get(SlashServer.Command, name: name) do
      {:ok, %SlashServer.Command{name: name, description: desc, response: resp}} ->
        resp = construct_response(name, desc, resp)
        json(conn, resp)

      _ ->
        resp =
          construct_response(
            name,
            "Something went wrong",
            "Please contact an admin to fix this problem"
          )

        json(conn, resp)
    end
  end

  defp respond_to_slash(conn, _params) do
    json(conn, %{type: 1})
  end

  def slash(conn, params) do
    if valid_request?(conn, params) do
      respond_to_slash(conn, params)
    else
      conn
      |> put_status(401)
      |> json(%{})
    end
  end
end
