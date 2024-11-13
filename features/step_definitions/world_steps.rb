# frozen_string_literal: true

Given('I am logged in as a user') do
  @user = FactoryBot.create(:user)
  login_as(@user, scope: :user)
end

Given(/^(?:I am on|I visit) the single player page$/) do
  visit single_player_path
end

When('I fill in the world name field with {string}') do |world_name|
  fill_in 'World Name', with: world_name
end

When('I leave {string} blank') do |field_label|
  fill_in field_label, with: ''
end

Then('I should see {string} in the list of saved worlds') do |world_name|
  expect(page).to have_css('.world-card', text: world_name)
end

Then('I should see the message {string}') do |message|
  expect(page).to have_content(message)
end

Given('I have created worlds named {string} and {string}') do |world_a, world_b|
  FactoryBot.create(:world, name: world_a, creator: @user)
  FactoryBot.create(:world, name: world_b, creator: @user)
end

Given('there is a world created by another user with the name {string}') do |world_name|
  other_user = FactoryBot.create(:user, email: 'other_user@example.com') # Specify a unique email
  FactoryBot.create(:world, name: world_name, creator: other_user)
end

When('I attempt to visit the {string} page') do |world_name|
  world = World.find_by(name: world_name)
  visit game_path(world)
end

Then('I should be on the single player page') do
  expect(current_path).to eq(single_player_path)
end
