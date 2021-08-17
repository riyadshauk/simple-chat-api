# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

# db/seeds.rb
user1 = User.create!(
  username: "seedUser1"
)

user2 = User.create!(
  username: "seedUser2"
)

Chat.create!(
  [
    {
      message: "cool message",
      from: user1,
      to: user2,
      timestamp: "2021-08-16T20:30:42Z",
    },
    {
      message: "cooler message",
      from: user1,
      to: user2,
      timestamp: "2021-08-16T20:31:42Z",
    },
    {
      message: "even cooler message",
      from: user2,
      to: user1,
      timestamp: "2021-08-16T20:32:42Z",
    },
    {
      message: "even cooler message!",
      from: user2,
      to: user1,
      timestamp: "2021-08-16T20:33:42Z",
    }
  ]
)