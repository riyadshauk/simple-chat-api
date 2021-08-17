# starter code from following https://evilmartians.com/chronicles/graphql-on-rails-1-from-zero-to-the-first-query , FactoryBot cheatsheet: https://devhints.io/factory_bot#associations
FactoryBot.define do
  factory :user do
    # Use sequence to make sure that the value is unique
    sequence(:username) { |n| "user-#{n}" }
  end

  factory :chat do
    sequence(:message) { |n| "chat-#{n}" }
    association :from, factory: :user
    association :to, factory: :user
  end
end
