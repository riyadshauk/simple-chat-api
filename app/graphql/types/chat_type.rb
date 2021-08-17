module Types
  class ChatType < Types::BaseObject
    field :id, ID, null: false
    field :timestamp, GraphQL::Types::ISO8601DateTime, null: true
    field :message, String, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    field :from_id, Integer, null: true
    field :to_id, Integer, null: true
    
    # https://dev.to/isalevine/ruby-on-rails-graphql-api-tutorial-filtering-with-custom-fields-and-class-methods-3efd
    field :history_since, GraphQL::Types::ISO8601DateTime, null: true
  end
end
