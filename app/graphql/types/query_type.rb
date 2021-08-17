module Types
  class QueryType < Types::BaseObject
    # Add `node(id: ID!) and `nodes(ids: [ID!]!)`
    include GraphQL::Types::Relay::HasNodeField
    include GraphQL::Types::Relay::HasNodesField

    # Add root-level fields here.
    # They will be entry points for queries on your schema.

    # for [better] solutions to N+1 problem (may be explored later):
    # https://evilmartians.com/chronicles/graphql-on-rails-1-from-zero-to-the-first-query
    #  -> https://github.com/DmitryTsepelev/ar_lazy_preload
    #  -> https://github.com/Shopify/graphql-batch

    field :chats,
      [Types::ChatType],
      null: false do
        description "Returns a list of chat messages [up to a timestamp for a given user]"
        argument :from_user_id, ID, required: false
        argument :to_user_id, ID, required: false
        argument :history_since, GraphQL::Types::ISO8601DateTime, required: false
      end
    def chats(from_user_id: nil, to_user_id: nil, history_since: nil)
      if from_user_id == nil || to_user_id == nil || history_since == nil
        Chat.all
      end

      Chat.with_api_filters(timestamp_gte: history_since, from_id_in: from_user_id, to_id_in: to_user_id).with_sorting('timestamp.dsc')
    end

    field :allChats,
      [Types::ChatType],
      null: false,
      description: "Returns a list of all chat messages"
    def allChats
      Chat.all
    end

    # for the purposes of demoing, adding a users field
    field :users,
      [Types::UserType],
      null: false,
      description: "Returns a list of users [for demo purposes]"
    def users
      User.all
    end

    # TODO: remove me
    field :test_field, String, null: false,
      description: "An example field added by the generator"
    def test_field
      "Hello World!"
    end
  end
end
