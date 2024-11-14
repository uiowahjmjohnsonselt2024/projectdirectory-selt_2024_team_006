# frozen_string_literal: true

Given('a user with {int} shards exists') do |shards|
  unique_email = "user_#{Time.now.to_i}@example.com"
  @user = create(:user, shards_balance: shards, email: unique_email)
end

Given('an item with a price of {int} shards exists') do |price|
  @item = create(:item, price: price, name: 'Magic Sword', description: 'A sword with magical properties', image_url: 'https://www.wikihow.com/images/thumb/4/41/Get-the-URL-for-Pictures-Draft-Step-1.jpg/v4-460px-Get-the-URL-for-Pictures-Draft-Step-1.jpg.webp')
end

Given('the user is signed in') do
  login_as(@user, scope: :user)
end

Given('I am on the shop page') do
  visit shop_index_path
end

When('the user buys an item priced at {int} shards') do |price|
  item_div = find('p', text: "Price: #{price} Shards").find(:xpath, '..')
  item_div.find_button('Buy').click
end

When('the user sells the item') do
  find_button('Sell', match: :first).click
end

Then("the user's shard balance should be {int}") do |expected_balance|
  @user.reload
  expect(@user.shards_balance).to eq(expected_balance)
end

Then('I should not see {string}') do |expected|
  expect(page).to_not have_content(expected)
end
