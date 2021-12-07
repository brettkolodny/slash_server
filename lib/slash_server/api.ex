defmodule SlashServer.Api do
  use Ash.Api

  resources do
    registry SlashServer.Registry
  end
end
