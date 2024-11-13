# frozen_string_literal: true

Given('I am signed in as a user') do
  @user = User.create!(email: 'user@example.com', password: 'password123')
  login_as(@user, scope: :user)
end

Given('I am on the shard purchase page') do
  stub_request(:get, 'https://api.exchangerate-api.com/v4/latest/USD')
    .to_return(
      status: 200,
      body: { rates: { 'USD' => 1.0, 'CAD' => 1.25, 'GBP' => 0.75, 'EUR' => 0.85, 'JPY' => 110.0 } }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

  visit new_shards_purchase_path
end

Given('I am purchasing shards with GBP') do
  stub_request(:get, 'https://api.exchangerate-api.com/v4/latest/GBP')
    .to_return(
      status: 200,
      body: { rates: { 'USD' => 1.35, 'GBP' => 1.0, 'EUR' => 1.2, 'JPY' => 110.0 } }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
end

When('I fill in {string} with {string}') do |field, value|
  fill_in field, with: value
end

When('I select {string} from {string}') do |option, field|
  select option, from: field
end

Then('my shard balance should be {string}') do |balance|
  user = User.first
  expect(user.shards_balance.to_s).to eq(balance)
end

Then('Shards Amount: {string}') do |amount|
  expect(page).to have_content("Shards Amount: #{amount}")
end
