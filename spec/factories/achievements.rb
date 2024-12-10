# spec/factories/achievements.rb
FactoryBot.define do
  factory :achievement do
    name { 'Test Achievement' }
    target { 100 } # Set a reasonable default for the target
  end
end
