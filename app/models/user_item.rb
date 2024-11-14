# frozen_string_literal: true

class UserItem < ApplicationRecord
  belongs_to :user
  belongs_to :item
end
