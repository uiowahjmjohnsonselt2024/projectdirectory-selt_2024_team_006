# frozen_string_literal: true

class PlayerProgress < ApplicationRecord
  belongs_to :user
  belongs_to :achievement

  validates :achievement, presence: true
  validates :current_progress, numericality: { greater_than_or_equal_to: 0 }

  def progress_percentage
    (safe_current_progress.to_f / safe_target) * 100
  end

  def completed?
    safe_current_progress >= safe_target
  end

  private

  def safe_current_progress
    current_progress || 0
  end

  def safe_target
    achievement&.target || 0
  end
end
