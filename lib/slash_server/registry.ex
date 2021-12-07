defmodule SlashServer.Registry do
  use Ash.Registry,
    extensions: [Ash.Registry.ResourceValidations]

  entries do
    entry SlashServer.CommandGroup
    entry SlashServer.Command
  end
end
