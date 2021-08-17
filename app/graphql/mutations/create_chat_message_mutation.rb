module Mutations
  class CreateChatMessageMutation < Mutations::BaseMutation
    argument :from_user_id, Integer, required: true
    argument :to_user_id, Integer, required: true
    argument :timestamp, GraphQL::Types::ISO8601DateTime, required: false
    argument :message, String, required: true

    def resolve(from_user_id:, to_user_id:, timestamp: nil, message:)
      chat = Chat.new(
        from_id: from_user_id,
        to_id: to_user_id,
        timestamp: timestamp,
        message: message
      )

      if chat.save
        { chat: chat }
      else
        { errors: chat.errors.full_messages }
      end
    end
  end
end