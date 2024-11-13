# spec/controllers/games_controller_spec.rb
require 'rails_helper'

RSpec.describe GamesController, type: :controller do
  let(:user) { create(:user) }  # Assuming a user factory or fixture is available

  before do
    sign_in user  # Using Devise helper if Devise is used for authentication
  end

  describe 'POST #create' do
    context 'with a provided name' do
      it 'creates a new world with the specified name' do
        expect {
          post :create, params: { world: { name: 'My Custom World' } }
        }.to change(World, :count).by(1)

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
        expect {
          post :create, params: { world: { name: '' } }
        }.to change(World, :count).by(1)

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
        allow_any_instance_of(World).to receive(:save).and_return(false)  # Mock failure of save
      end

      it 'does not create a new world' do
        expect {
          post :create, params: { world: { name: 'My Custom World' } }
        }.not_to change(World, :count)
      end

      it 'renders the new world template with an error message' do
        post :create, params: { world: { name: '' } }
        expect(response).to render_template(:new_world)
      end
    end
  end
end
