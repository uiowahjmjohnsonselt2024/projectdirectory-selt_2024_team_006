# frozen_string_literal: true

class PlayerProgress < ApplicationRecord
  belongs_to :user
  belongs_to :achievement

  def progress_percentage
    (current_progress.to_f / achievement.target) * 100
  end

  def completed?
    current_progress >= achievement.target
  end
end