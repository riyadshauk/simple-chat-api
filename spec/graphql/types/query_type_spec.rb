# init code from https://evilmartians.com/chronicles/graphql-on-rails-1-from-zero-to-the-first-query
require "rails_helper"

RSpec.describe Types::QueryType do
  describe "allChats" do
    let!(:chats) { FactoryBot.create_pair(:chat) }

    let(:query) do
      %(query {
        allChats {
          message
        }
      })
    end

    subject(:result) do
      SimpleChatApiSchema.execute(query).as_json
    end

    it "returns all chats" do
      expect(result.dig("data", "allChats")).to match_array(
        chats.map { |chat| { "message" => chat.message } }
      )
    end
  end

# TODO can add more tests for more graphql queries here...
end
