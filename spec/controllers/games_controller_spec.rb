# frozen_string_literal: true

# spec/controllers/games_controller_spec.rb
require 'rails_helper'

RSpec.describe GamesController, type: :controller do
  let(:user) { create(:user) }
  let!(:world) { create(:world, creator_id: user.id) }

  before do
    sign_in user
  end
  describe 'GET #single_player' do
    it 'assigns @saved_worlds and renders the single_player template' do
      get :single_player

      expect(assigns(:saved_worlds)).to eq([world]) # Check that @saved_worlds is assigned correctly
      expect(response).to render_template(:single_player) # Ensure it renders the correct template
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
      it 'assigns @world and renders the show template' do
        get :show, params: { id: world.id }

        expect(assigns(:world)).to eq(world)
        expect(response).to render_template(:show)
      end
    end

    context 'when the world does not exist or does not belong to the user' do
      it 'redirects to single_player_path with an alert message' do
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

    context 'with a blank name' do
      it 'creates a new world with the default name "Default World"' do
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
end
