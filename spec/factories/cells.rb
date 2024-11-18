# frozen_string_literal: true

FactoryBot.define do
  factory :cell do
    association :world
    x { 0 }
    y { 0 }
    content { 'empty' }
  end
end
