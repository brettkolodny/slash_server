defmodule SlashServer.Repo do
  use AshPostgres.Repo,
    otp_app: :slash_server,
    adapter: Ecto.Adapters.Postgres
end
