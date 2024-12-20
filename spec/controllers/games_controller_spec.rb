# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GamesController, type: :controller do
  before do
    sign_in user
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    allow(ChatGptService).to receive(:call).and_return(
      { 'choices' => [{ 'message' => { 'content' => 'Test response.' } }] }
    )
    allow(ChatGptService).to receive(:generate_image).and_return({ 'data' => [{ 'url' => 'default_image_url' }] })
  end

  let(:user) { create(:user) }
  let(:other_user) { create(:user, email: 'unique_email@example.com') }
  let!(:world) { create(:world, creator_id: user.id, is_public: false) }
  let!(:other_world) { create(:world, creator_id: other_user.id) }

  describe 'GET #single_player' do
    it 'assigns @saved_worlds and renders the single_player template' do
      get :single_player

      expect(assigns(:saved_worlds)).to eq([world])
      expect(response).to render_template(:single_player)
    end
  end

  describe 'GET #new_world' do
    it 'initializes a new world instance and renders the new_world template' do
      get :new_world

      expect(assigns(:world)).to be_a_new(World)
      expect(response).to render_template(:new_world)
    end
  end

  describe 'GET #show' do
    context 'when the world exists and belongs to the user' do
      it 'assigns the requested world to @world' do
        get :show, params: { id: world.id }
        expect(assigns(:world)).to eq(world)
      end

      it 'loads the cells in the correct order' do
        get :show, params: { id: world.id }
        expect(assigns(:cells).uniq.count).to eq(49)
        expect(assigns(:cells).first.x).to eq(0)
        expect(assigns(:cells).first.y).to eq(0)
      end

      it 'renders the show template' do
        get :show, params: { id: world.id }
        expect(response).to render_template(:show)
      end
    end

    context 'when the world does not belong to the user' do
      it 'redirects to single player path with an alert' do
        get :show, params: { id: other_world.id }
        expect(response).to redirect_to(single_player_path)
        expect(flash[:alert]).to eq('World not found.')
      end
    end

    context 'when the world does not exist' do
      it 'redirects to single player path with an alert' do
        get :show, params: { id: 9999 }
        expect(assigns(:world)).to be_nil
        expect(response).to redirect_to(single_player_path)
        expect(flash[:alert]).to eq('World not found.')
      end
    end
  end

  describe 'POST #create' do
    context 'with a provided name' do
      it 'creates a new world with the specified name' do
        expect do
          post :create, params: { world: { name: 'My Custom World' } }
        end.to change(World, :count).by(1)

        created_world = World.last
        expect(created_world.name).to eq('My Custom World')
        expect(created_world.creator_id).to eq(user.id)
      end

      it 'redirects to the single player path with a success message' do
        post :create, params: { world: { name: 'My Custom World' } }
        expect(response).to redirect_to(single_player_path)
        expect(flash[:notice]).to eq('World created successfully!')
      end
    end

    context 'when the user does not have enough shards' do
      before do
        user.update(shards_balance: 5)
      end

      it 'does not create a new world' do
        expect do
          post :create, params: { world: { name: 'My Custom World' } }
        end.not_to change(World, :count)
      end

      it 'redirects to the worlds path with an error message' do
        post :create, params: { world: { name: 'My Custom World' } }
        expect(response).to redirect_to(worlds_path)
        expect(flash[:alert]).to eq(
          "You don't have enough shards to create a world. Creating a new world costs 10 shards!"
        )
      end
    end

    context 'with a blank name' do
      it 'creates a new world with the default name "New World"' do
        expect do
          post :create, params: { world: { name: '' } }
        end.to change(World, :count).by(1)

        created_world = World.last
        expect(created_world.name).to eq('New World')
        expect(created_world.creator_id).to eq(user.id)
      end

      it 'redirects to the single player path with a success message' do
        post :create, params: { world: { name: '' } }
        expect(response).to redirect_to(single_player_path)
        expect(flash[:notice]).to eq('World created successfully!')
      end
    end

    context 'when world creation fails' do
      before do
        allow_any_instance_of(World).to receive(:save).and_return(false)
      end

      it 'does not create a new world' do
        expect do
          post :create, params: { world: { name: 'My Custom World' } }
        end.not_to change(World, :count)
      end

      it 'renders the new world template with an error message' do
        post :create, params: { world: { name: '' } }
        expect(response).to render_template(:new_world)
      end
    end
  end

  describe 'POST #join' do
    before do
      sign_in other_user
    end

    context 'when the world is public' do
      it 'allows the player to join the world' do
        post :join, params: { id: world.id }

        expect(response).to redirect_to(game_path(world))
        expect(flash[:notice]).to eq('You have joined the world!')
      end
    end

    context 'when the world is private and the player is not the creator' do
      before { world.update!(is_public: false) }

      it 'redirects to single_player_path with an alert' do
        post :join, params: { id: world.id }

        expect(response).to redirect_to(game_path(world))
      end
    end

    context 'when the world does not exist' do
      it 'redirects to single_player_path with an alert' do
        post :join, params: { id: 9999 }

        expect(response).to redirect_to(single_player_path)
        expect(flash[:alert]).to eq('World not found or access denied.')
      end
    end

    context 'when there is an error placing the player' do
      before do
        allow_any_instance_of(World).to receive(:place_player).and_raise('No empty squares available in the world')
      end

      it 'redirects to single_player_path with the error message' do
        post :join, params: { id: world.id }

        expect(response).to redirect_to(single_player_path)
        expect(flash[:alert]).to eq('No empty squares available in the world')
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'when the world exists and belongs to the user' do
      it 'deletes the world and redirects to the single player path with a success message' do
        expect do
          delete :destroy, params: { id: world.id }
        end.to change(World, :count).by(-1)

        expect(response).to redirect_to(single_player_path)
      end
    end

    context 'when the world does not belong to the user' do
      it 'does not delete the world and redirects to the single player path with an alert' do
        expect do
          delete :destroy, params: { id: other_world.id }
        end.not_to change(World, :count)

        expect(response).to redirect_to(single_player_path)
        expect(flash[:alert]).to eq('World not found.')
      end
    end

    context 'when the world does not exist' do
      it 'does not delete any world and redirects to the single player path with an alert' do
        expect do
          delete :destroy, params: { id: 9999 }
        end.not_to change(World, :count)

        expect(response).to redirect_to(single_player_path)
        expect(flash[:alert]).to eq('World not found.')
      end
    end
  end

  describe '#find_world' do
    context 'when the world exists and belongs to the user' do
      it 'returns the world' do
        sign_in user
        controller.params = { id: world.id }

        found_world = controller.send(:find_world)
        expect(found_world).to eq(world)
      end
    end

    context 'when the world does not belong to the user' do
      let(:other_user) { create(:user, email: 'unique_email3@example.com') }
      let(:world) { create(:world, creator_id: other_user.id, is_public: false) }

      before do
        sign_in user
      end

      it 'returns nil' do
        controller.params = { id: world.id }

        found_world = controller.send(:find_world)
        expect(found_world).to be_nil
      end
    end
  end

  describe '#track_achievement_progress' do
    let!(:achievement) { create(:achievement, name: 'First World', target: 1) }

    before do
      create(:player_progress, user: user, achievement: achievement, current_progress: 0)
    end

    it 'creates player progress if not already present and increments progress' do
      expect do
        controller.send(:track_achievement_progress, 'First World')
      end.to change {
        user.player_progresses.find_by(achievement: achievement).current_progress || 0
      }.by(1)
    end

    it 'displays a flash message for a completed achievement' do
      create(:player_progress, user: user, achievement: achievement, current_progress: 1)
      controller.send(:track_achievement_progress, 'First World')
      expect(flash[:success]).to match(/Achievement unlocked: First World Claim your reward./)
    end
  end
end
