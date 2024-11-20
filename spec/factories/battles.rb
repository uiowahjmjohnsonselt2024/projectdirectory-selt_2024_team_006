# frozen_string_literal: true

FactoryBot.define do
  factory :battle do
    association :world
    association :cell
    association :player, factory: :user
    state { 'active' }
    turn { 'player' }
    enemy_data { { 'health' => 100, 'attack' => 10, 'narration' => 'A fierce enemy appears!' } }
  end
end
