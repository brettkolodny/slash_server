defmodule SlashServer.CommandGroup do
  use Ash.Resource, data_layer: Ash.DataLayer.Ets

  attributes do
    uuid_primary_key :id

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

    relationships do
      has_many :commands, SlashServer.Command, destination_field: :command_group_id
    end

    # This is set on create
    create_timestamp :inserted_at
    # This is updated on all updates
    update_timestamp :updated_at
  end

  identities do
    identity :unique_name, [:name]
  end

  actions do
    create :create
    read :read
    update :update
    destroy :destroy
  end
end
