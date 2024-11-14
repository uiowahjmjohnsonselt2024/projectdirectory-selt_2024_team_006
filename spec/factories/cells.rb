FactoryBot.define do
  factory :cell do
    x { 1 }
    y { 1 }
    world { nil }
    content { "MyString" }
  end
end
