# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorldsController, type: :controller do
  let(:user) { create(:user, email: "user#{Time.now.to_i}@example.com", shards_balance: 0) }
  let(:world) { create(:world, creator: user) }

  before do
    sign_in user
    allow_any_instance_of(World).to receive(:generate_grid)
    create(:cell, world: world, x: 0, y: 0, content: 'player')
    create(:cell, world: world, x: 0, y: 1, content: 'empty')
    create(:cell, world: world, x: 1, y: 0, content: 'treasure')
    create(:cell, world: world, x: 1, y: 1, content: 'enemy')
  end

  describe 'POST #move' do
    context 'when the player is on the grid' do
      it 'moves the player to an empty cell' do
        post :move, params: { id: world.id, direction: 'down' }

        updated_player_cell = world.cells.find_by(x: 0, y: 0)
        updated_empty_cell = world.cells.find_by(x: 0, y: 1)

        expect(updated_player_cell.content).to eq('empty')
        expect(updated_empty_cell.content).to eq('player')
      end

      it 'moves right and then left' do
        post :move, params: { id: world.id, direction: 'right' }
        post :move, params: { id: world.id, direction: 'left' }

        updated_player_cell = world.cells.find_by(x: 0, y: 0)
        updated_empty_cell = world.cells.find_by(x: 0, y: 1)

        expect(updated_player_cell.content).to eq('player')
        expect(updated_empty_cell.content).to eq('empty')
      end

      it 'handles non-move' do
        post :move, params: { id: world.id, direction: '' }

        updated_player_cell = world.cells.find_by(x: 0, y: 0)
        updated_empty_cell = world.cells.find_by(x: 0, y: 1)

        expect(updated_player_cell.content).to eq('empty')
        expect(updated_empty_cell.content).to eq('empty')
      end

      it 'moves the player to a treasure cell and updates shards balance' do
        post :move, params: { id: world.id, direction: 'right' }

        updated_player_cell = world.cells.find_by(x: 0, y: 0)
        updated_treasure_cell = world.cells.find_by(x: 1, y: 0)

        expect(updated_player_cell.content).to eq('empty')
        expect(updated_treasure_cell.content).to eq('player')

        expect(user.reload.shards_balance).to eq(10)
        expect(flash[:notice]).to eq('You found a treasure and earned 10 shards!')
      end

      it 'moves the player to an enemy cell and flashes an alert' do
        post :move, params: { id: world.id, direction: 'down' }
        post :move, params: { id: world.id, direction: 'right' }

        updated_player_cell = world.cells.find_by(x: 0, y: 1)
        updated_enemy_cell = world.cells.find_by(x: 1, y: 1)

        expect(updated_player_cell.content).to eq('empty')
        expect(updated_enemy_cell.content).to eq('player')
        expect(flash[:alert]).to eq('You encountered an enemy! Prepare for battle.')
      end
    end

    context 'when the move is invalid' do
      it 'does not move the player and flashes an alert' do
        post :move, params: { id: world.id, direction: 'up' }

        updated_player_cell = world.cells.find_by(x: 0, y: 0)

        expect(updated_player_cell.content).to eq('player')
        expect(flash[:alert]).to eq('Invalid move!')
      end
    end

    context 'when the world does not belong to the user' do
      let(:other_user) { create(:user) }
      let(:other_world) { create(:world, creator: other_user) }

      it 'redirects to the single_player_path' do
        post :move, params: { id: other_world.id, direction: 'down' }
        expect(response).to redirect_to(single_player_path)
      end
    end
  end
end
