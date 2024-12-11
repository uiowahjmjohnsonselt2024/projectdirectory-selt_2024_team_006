# frozen_string_literal: true

Given('I have some achievements and progress') do
  @achievement1 = Achievement.create!(name: 'First Kill', target: 1, reward: 10)
  @achievement2 = Achievement.create!(name: 'Collector', target: 50, reward: 20)
  @progress1 = @user.player_progresses.create!(achievement: @achievement1, current_progress: 1, claimed: false)
  @progress2 = @user.player_progresses.create!(achievement: @achievement2, current_progress: 50, claimed: false)
end

When('I visit the achievements page') do
  visit achievements_path
end

Then('I should see all achievements') do
  expect(page).to have_content('First Kill')
  expect(page).to have_content('Collector')
end

Then('I should see my progress for each achievement') do
  @achievement1 = Achievement.find_by(name: 'First Kill')
  @achievement2 = Achievement.find_by(name: 'Collector')

  [@achievement1, @achievement2].each do |achievement|
    progress = "#{achievement.target}/#{achievement.target}"
    expect(page).to have_content(progress)
  end
end

Given('I have completed an achievement that is not claimed') do
  @achievement = Achievement.create!(name: 'Achiever', target: 1, reward: 10)
  @progress = @user.player_progresses.create!(achievement: @achievement, current_progress: 1, claimed: false)
end

When('I claim the achievement') do
  visit achievements_path
  expect(page).to have_button('Claim Reward')
  click_button 'Claim Reward'
end

Then('my shards balance should increase by the reward amount') do
  @user.reload
  expect(@user.shards_balance).to eq(10)
end

Then('the achievement should be marked as claimed') do
  @progress.reload
  expect(@progress.claimed).to be true
end
