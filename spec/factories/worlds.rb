# frozen_string_literal: true

FactoryBot.define do
  factory :world do
    association :creator, factory: :user
    name { 'MyString' }
    creator_id { 1 }
  end
end
