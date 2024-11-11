# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'User Authentication', type: :feature do
  let(:user) { create(:user) }

  scenario 'User signs up successfully' do
    visit new_user_registration_path

    fill_in 'Email', with: 'newuser@example.com'
    fill_in 'Password', with: 'password123'
    fill_in 'Password confirmation', with: 'password123'
    click_button 'Sign up'

    expect(page).to have_content('Welcome! You have signed up successfully.')
  end

  scenario 'User signs in successfully' do
    user

    visit new_user_session_path
    fill_in 'Email', with: 'test@example.com'
    fill_in 'Password', with: 'password123'
    click_button 'Log in'

    expect(page).to have_content('Signed in successfully.')
  end

  scenario 'User logs out successfully' do
    user

    visit new_user_session_path
    fill_in 'Email', with: 'test@example.com'
    fill_in 'Password', with: 'password123'
    click_button 'Log in'

    expect(page).to have_content('Signed in successfully')

    click_link_or_button 'Sign Out'

    expect(page).to have_content('Signed out successfully.')
  end
end
