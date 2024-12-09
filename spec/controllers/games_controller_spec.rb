# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GamesController, type: :controller do
  before do
    sign_in user
    allow(ChatGptService).to receive(:call).and_return(
      { 'choices' => [{ 'message' => { 'content' => 'Test response.' } }] }
    )
    allow(ChatGptService).to receive(:generate_image).and_return({ 'data' => [{ 'url' => 'default_image_url' }] })
  end

  let(:user) { create(:user) }
  let(:other_user) { create(:user, email: 'unique_email@example.com') }
  let!(:world) { create(:world, creator_id: user.id) }
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
      it 'returns nil' do
        sign_in other_user
        controller.params = { id: world.id }

        found_world = controller.send(:find_world)
        expect(found_world).to be_nil
      end
    end
  end
  describe "POST #host_world" do
    it "marks a world as hosted and assigns an IP address" do
      post :host_world, params: { id: world.id, ip_address: '127.0.0.1' }

      world.reload
      expect(world.is_hosted).to be_truthy
      expect(world.host_ip).to eq('127.0.0.1')
      expect(response).to redirect_to(host_active_game_path(world))
      expect(flash[:notice]).to eq("Hosting world: #{world.name} at 127.0.0.1")
    end
  end
  describe "POST #join_world" do
    let(:host_world) { create(:world, is_hosted: true, host_ip: '127.0.0.1') }

    it "allows a player to join a hosted world" do
      post :join_world, params: { ip_address: '127.0.0.1' }

      user_world_state = UserWorldState.find_by(user: user, world: host_world)
      expect(user_world_state).not_to be_nil
      expect(user_world_state.health).to eq(100)
      expect(response).to redirect_to(play_world_path(host_world))
      expect(flash[:notice]).to eq("Joined world: #{host_world.name}!")
    end

    it "fails to join a non-hosted world" do
      post :join_world, params: { ip_address: '192.168.1.1' }

      expect(flash[:alert]).to eq("No active game found at 192.168.1.1.")
      expect(response).to redirect_to(join_game_path)
    end
  end
end
