class User < ApplicationRecord
  has_many :chats # , dependent: :destroy # future usecase: delete posts by provided user
end
