# frozen_string_literal: true

class UserWorldState < ApplicationRecord
  belongs_to :user
  belongs_to :world

  before_create :set_default_health

  private

  def set_default_health
    self.health ||= 100
  end
end
