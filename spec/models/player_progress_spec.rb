# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PlayerProgress, type: :model do
  let(:achievement) { Achievement.create!(name: 'Test Achievement', target: 100) }
  let(:user) { User.create!(email: 'test@example.com', password: 'password') }
  let(:progress) { PlayerProgress.create!(user: user, achievement: achievement, current_progress: 50) }

  describe '#progress_percentage' do
    it 'calculates the correct progress percentage' do
      expect(progress.progress_percentage).to eq(50.0)
    end
  end
end
