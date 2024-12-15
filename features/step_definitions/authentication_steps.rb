# frozen_string_literal: true

Given('I am on the sign up page') do
  visit new_user_registration_path
end

Given('I am on the sign in page') do
  visit new_user_session_path
end

Given('I am logged in as a user') do
  @user ||= User.create!(email: 'test@example.com', password: 'password')
  login_as(@user, scope: :user)
end

Given('a user exists with email {string} and password {string}') do |email, password|
  User.create(email: email, password: password, password_confirmation: password)
end

Given('I am signed in as {string}') do |email|
  user = User.find_by(email: email)
  visit new_user_session_path
  fill_in 'Email', with: user.email
  fill_in 'Password', with: 'password123'
  click_button 'Log in'
end

When('I press {string}') do |button|
  click_button button
end

When('I click {string}') do |link|
  click_button link
end

Then('I should see {string}') do |content|
  expect(page).to have_content(content)
end
Given('a user with email {string} exists') do |email|
  User.create!(email: email, password: 'password123')
end

Given('no user with email {string} exists') do |email|
  User.where(email: email).delete_all
end

Then('a user with email {string} should exist') do |email|
  user = User.find_by(email: email)
  expect(user).not_to be_nil
end

Given("I am on the login page") do
  visit new_user_session_path
end

