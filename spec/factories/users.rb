# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    email { 'test@example.com' }
    password { 'password123' }
    password_confirmation { 'password123' }
    shards_balance { 100 }
  end
end
