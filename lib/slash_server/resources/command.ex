defmodule SlashServer.Command do
  use Ash.Resource, data_layer: Ash.DataLayer.Ets

  attributes do
    uuid_primary_key :command_id

    attribute :name, :string,
      allow_nil?: false,
      constraints: [
        max_length: 100,
        match: ~r/^([a-z])+-?([a-z])+$/i
      ]

    attribute :description, :string do
      allow_nil? false
      constraints max_length: 100
    end

    attribute :response, :string do
      allow_nil? false
      constraints max_length: 2000
    end

    # This is set on create
    create_timestamp :inserted_at
    # This is updated on all updates
    update_timestamp :updated_at
  end

  identities do
    identity :unique_name, [:name]
  end

  relationships do
    belongs_to :command_group, SlashServer.CommandGroup
  end

  actions do
    create :create
    read :read
    update :update
    destroy :destroy
  end
end
