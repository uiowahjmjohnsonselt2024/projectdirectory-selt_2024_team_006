# frozen_string_literal: true

class World < ApplicationRecord
  belongs_to :creator, class_name: 'User', foreign_key: 'creator_id'
end
