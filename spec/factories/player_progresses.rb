# frozen_string_literal: true

# spec/factories/player_progresses.rb
FactoryBot.define do
  factory :player_progress do
    user
    achievement
    current_progress { 0 } # Default to starting progress
  end
end
