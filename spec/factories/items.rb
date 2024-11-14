# frozen_string_literal: true

FactoryBot.define do
  factory :item do
    name { 'MyString' }
    description { 'MyText' }
    price { 1 }
    image_url { 'https://www.wikihow.com/images/thumb/4/41/Get-the-URL-for-Pictures-Draft-Step-1.jpg/v4-460px-Get-the-URL-for-Pictures-Draft-Step-1.jpg.webp' }
  end
end
