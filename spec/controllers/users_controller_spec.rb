# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  let(:user) { User.create!(email: 'test@example.com', password: 'password') }
  let(:item1) { Item.create!(name: 'Sword', image_url: 'url', price: 10) }
  let(:item2) { Item.create!(name: 'Shield', image_url: 'url', price: 15) }
  let(:achievement) { Achievement.create!(name: 'Test Achievement', reward: 50, target: 100) }
  let!(:progress) do
    PlayerProgress.create!(user: user, achievement: achievement, current_progress: 100, claimed: false)
  end

  before do
    sign_in user
    user.items << [item1, item2]
  end

  describe 'GET #show' do
    it 'authenticates the user' do
      sign_out user
      get :show
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'assigns @user as the current user' do
      get :show
      expect(assigns(:user)).to eq(user)
    end

    it 'assigns @inventory_items with the users items' do
      get :show
      expect(assigns(:inventory_items)).to match_array([item1, item2])
    end

    it 'renders the show template' do
      get :show
      expect(response).to render_template(:show)
    end
  end

  describe 'GET #achievements' do
    it 'assigns @achievements with all achievements' do
      get :achievements
      expect(assigns(:achievements)).to include(achievement)
    end

    it 'assigns @player_progress with user progress indexed by achievement' do
      get :achievements
      expect(assigns(:player_progress)[achievement.id]).to eq(progress)
    end
  end

  describe 'POST #claim_achievement' do
    context 'when the achievement can be claimed' do
      it 'processes the claim and updates the user shards balance' do
        post :claim_achievement, params: { achievement_id: achievement.id }
        expect(user.reload.shards_balance).to eq(50)
        expect(progress.reload.claimed).to be true
      end

      it 'sets a success flash message' do
        post :claim_achievement, params: { achievement_id: achievement.id }
        expected_message = 'Achievement unlocked and reward claimed! ' \
                           "You received #{achievement.reward} shards."
        expect(flash[:success]).to eq(expected_message)
      end

      it 'redirects to the achievements page' do
        post :claim_achievement, params: { achievement_id: achievement.id }
        expect(response).to redirect_to(achievements_path)
      end
    end

    context 'when the achievement cannot be claimed' do
      before { progress.update!(claimed: true) }

      it 'does not update the user shards balance' do
        post :claim_achievement, params: { achievement_id: achievement.id }
        expect(user.reload.shards_balance).to eq(0)
      end

      it 'sets an error flash message' do
        post :claim_achievement, params: { achievement_id: achievement.id }
        expect(flash[:alert]).to eq('Achievement not completed or already claimed.')
      end

      it 'redirects to the achievements page' do
        post :claim_achievement, params: { achievement_id: achievement.id }
        expect(response).to redirect_to(achievements_path)
      end
    end

    context 'when the progress is incomplete' do
      before { progress.update!(current_progress: 50, claimed: false) }

      it 'does not update the user shards balance' do
        post :claim_achievement, params: { achievement_id: achievement.id }
        expect(user.reload.shards_balance).to eq(0)
      end

      it 'sets an error flash message' do
        post :claim_achievement, params: { achievement_id: achievement.id }
        expect(flash[:alert]).to eq('Achievement not completed or already claimed.')
      end

      it 'redirects to the achievements page' do
        post :claim_achievement, params: { achievement_id: achievement.id }
        expect(response).to redirect_to(achievements_path)
      end
    end
  end
end
