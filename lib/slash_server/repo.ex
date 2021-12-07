defmodule SlashServer.Repo do
  use Ecto.Repo,
    otp_app: :slash_server,
    adapter: Ecto.Adapters.Postgres
end
