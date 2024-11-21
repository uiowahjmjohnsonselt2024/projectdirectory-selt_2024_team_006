# frozen_string_literal: true

FactoryBot.define do
  factory :user_world_state do
    user { nil }
    world { nil }
    health { 1 }
  end
end
