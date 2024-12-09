# frozen_string_literal: true

class Achievement < ApplicationRecord
  has_many :player_progresses, dependent: :destroy
  has_many :users, through: :player_progresses
end