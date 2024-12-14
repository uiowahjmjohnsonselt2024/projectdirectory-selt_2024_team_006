# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorldsController, type: :controller do
  let(:user) { create(:user, email: "user#{Time.now.to_i}@example.com", shards_balance: 50) }
  let(:world) { create(:world, creator: user, is_public: false) }
  let(:item1) { Item.create!(name: 'Sword', image_url: 'url', price: 10, damage: 20) }
  let(:item2) { Item.create!(name: 'Shield', image_url: 'url', price: 15, damage: 30) }
  let!(:first_kill) { create(:achievement, name: 'First Kill', target: 1) }
  let!(:slayer) { create(:achievement, name: 'Slayer', target: 10) }

  before do
    sign_in user
    user.items << [item1, item2]
    create(:player_progress, user: user, achievement: first_kill, current_progress: 0)
    create(:player_progress, user: user, achievement: slayer, current_progress: 0)

    allow(GameChannel).to receive(:broadcast_to)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    allow(ChatGptService).to receive(:call).and_return(
      { 'choices' => [{ 'message' => { 'content' => 'Test response.' } }] }
    )
    allow(ChatGptService).to receive(:generate_image).and_return({ 'data' => [{ 'url' => 'default_image_url' }] })
    world.cells.destroy_all

    (0..6).each do |x|
      (0..6).each do |y|
        content = if x == 0 && y == 0
                    user.id.to_s
                  elsif x == 1 && y == 0
                    'treasure'
                  elsif x == 1 && y == 1
                    'enemy'
                  else
                    'empty'
                  end
        create(:cell, world: world, x: x, y: y, content: content)
      end
    end
    allow_any_instance_of(World).to receive(:generate_grid)
    expect(world.cells.count).to eq(49)
  end

  describe 'POST #shard_move' do
    let!(:player_cell) { create(:cell, world: world, x: 0, y: 0, content: user.id.to_s) }
    let!(:target_cell) { create(:cell, world: world, x: 1, y: 0, content: 'empty') }

    context 'when the world is not found' do
      it 'redirects to single player path with an error message' do
        post :shard_move, params: { id: 0 }
        expect(response).to redirect_to(single_player_path)
        expect(flash[:alert]).to eq('World not found.')
      end
    end

    context 'when the player is not on the grid' do
      before do
        player_cell.update!(content: 'empty')
      end

      it 'redirects to single player path with an error message' do
        post :shard_move, params: { id: world.id, x: 1, y: 0 }
        expect(flash[:alert]).to eq(nil)
      end
    end

    context 'when the player is already at the target location' do
      it 'redirects to game path with an error message' do
        post :shard_move, params: { id: world.id, x: 0, y: 0 }
        expect(response).to redirect_to(game_path(world))
        expect(flash[:alert]).to eq('Player already at this location')
      end
    end

    context 'when the player has insufficient funds for the move' do
      before do
        allow_any_instance_of(WorldsController).to receive(:insufficient_funds_for_move?).and_return(true)
      end

      it 'redirects to game path with an error message' do
        post :shard_move, params: { id: world.id, x: 1, y: 0 }
        expect(response).to redirect_to(game_path(world))
        expect(flash[:alert]).to eq('Insufficient funds')
      end
    end

    context 'when the player is in battle' do
      before do
        allow_any_instance_of(WorldsController).to receive(:player_in_battle?).and_return(true)
      end

      it 'redirects to game path with an error message' do
        post :shard_move, params: { id: world.id, x: 1, y: 0 }
        expect(response).to redirect_to(game_path(world))
        expect(flash[:alert]).to eq('Player is in battle')
      end
    end

    context 'when the move is valid' do
      it 'processes the shard move and updates the cells' do
        post :shard_move, params: { id: world.id, x: 1, y: 0 }

        expect(response).to redirect_to(game_path(world))
        expect(flash[:notice]).to be_present
      end
    end
  end

  describe 'POST #resolve_battle' do
    let(:battle) do
      create(
        :battle,
        world: world,
        cell: world.cells.find_by(x: 1, y: 1),
        player: user,
        enemy_data: { 'health' => 0, 'attack' => 10 },
        state: 'active'
      )
    end

    before { battle }

    context 'when the outcome is win' do
      it 'awards shards and destroys the battle' do
        allow_any_instance_of(Battle).to receive(:enemy_data).and_return({ 'health' => 10, 'attack' => 10,
                                                                           'max_health' => 10 })
        post :resolve_battle, params: { id: world.id, outcome: 'win' }
        expect(response).to redirect_to(game_path(world))
        expect(flash[:notice]).to match(/You defeated the enemy and earned \d+ shards!/)
        expect(Battle.exists?(battle.id)).to be_falsey
      end
    end

    context 'when the outcome is lose' do
      it 'shows a loss message and destroys the battle' do
        post :resolve_battle, params: { id: world.id, outcome: 'lose' }
        expect(response).to redirect_to(game_path(world))
        expect(flash[:alert]).to eq('You lost the battle!')
        expect(Battle.exists?(battle.id)).to be_falsey
      end
    end

    context 'when there is no active battle' do
      it 'redirects with an alert' do
        battle.update!(state: 'won')
        post :resolve_battle, params: { id: world.id, outcome: 'win' }
        expect(response).to redirect_to(game_path(world))
        expect(flash[:alert]).to eq('No active battle found!')
      end
    end
  end

  describe '#handle_enemy_turn' do
    let(:user_world_state) { create(:user_world_state, user: user, world: world, health: 20) }

    let(:battle) do
      create(
        :battle,
        world: world,
        cell: world.cells.find_by(x: 1, y: 1),
        player: user,
        enemy_data: { 'health' => 50, 'attack' => 15 },
        state: 'active',
        turn: user.id.to_s
      )
    end

    before do
      user_world_state
      battle
    end

    context 'when the enemy defeats the player' do
      it 'destroys the world and redirects with a game over message' do
        user_world_state.update!(health: 0)
        post :attack_with_item, params: { id: world.id, item_id: item1.id }
        expect(response).to redirect_to(single_player_path)
        expect(flash[:alert]).to match(/The enemy defeated you!/)
        expect(World.exists?(world.id)).to be_falsey
      end
    end

    context 'when the player survives the enemy attack' do
      it 'reduces player health and toggles turn' do
        allow_any_instance_of(WorldsController).to receive(:rand).and_return(5)

        post :attack_with_item, params: { id: world.id, item_id: item1.id }

        expect(user_world_state.reload.health).to eq(15)
        expect(battle.reload.turn).to eq(user.id.to_s)
      end
    end
  end

  describe 'POST #attack_with_item' do
    let(:user_world_state) { create(:user_world_state, user: user, world: world, health: 100) }
    let(:battle) do
      create(
        :battle,
        world: world,
        cell: world.cells.find_by(x: 1, y: 1),
        player: user,
        enemy_data: { 'health' => 50, 'attack' => 10 },
        state: 'active',
        turn: user.id.to_s
      )
    end

    before do
      user_world_state
      battle
    end

    context 'when the item is invalid' do
      it 'redirects with an alert' do
        post :attack_with_item, params: { id: world.id, item_id: nil }
        expect(response).to redirect_to(game_path(world))
        expect(flash[:alert]).to eq('Invalid item!')
      end
    end

    describe 'POST #acknowledge_encounter' do
      let(:cell) { world.cells.find_by(x: 0, y: 0) }

      before do
        cell.update!(encounter: 'A wild animal appears!')
      end

      context 'when the player is on a cell with an encounter' do
        it 'clears the encounter and redirects to the world page with a success message' do
          post :acknowledge_encounter, params: { id: world.id }

          expect(response).to redirect_to(game_path(world))
          expect(flash[:notice]).to eq('Encounter acknowledged!')
          expect(cell.reload.encounter).to be_nil
        end
      end

      context 'when the player is not on a cell with an encounter' do
        before do
          cell.update!(encounter: nil)
          cell.update!(content: 'empty')
        end

        it 'redirects to the world page with an alert message' do
          post :acknowledge_encounter, params: { id: world.id }

          expect(response).to redirect_to(game_path(world))
          expect(flash[:alert]).to eq('No cell found for the current user.')
        end
      end

      context 'when the world is not found' do
        it 'redirects to the single player path with an alert' do
          post :acknowledge_encounter, params: { id: 9999 }

          expect(response).to redirect_to(single_player_path)
          expect(flash[:alert]).to eq('World not found or access denied.')
        end
      end
    end

    context 'when tracking achievements for victory' do
      it 'increments progress for relevant achievements and resolves battle' do
        battle.update!(enemy_data: { 'health' => 0, 'attack' => 10, 'max_health' => 10 })

        expect_any_instance_of(WorldsController).to receive(:track_achievement_progress).with('First Kill')
        expect_any_instance_of(WorldsController).to receive(:track_achievement_progress).with('Slayer')

        post :attack_with_item, params: { id: world.id, item_id: item1.id }

        expect(Battle.exists?(battle.id)).to be_falsey
        expect(flash[:notice]).to match(/You defeated the enemy and earned \d+ shards!/)
      end
    end

    context 'when there is no active battle' do
      it 'redirects with an alert' do
        battle.update!(state: 'won')
        post :attack_with_item, params: { id: world.id, item_id: item1.id }
        expect(response).to redirect_to(game_path(world))
        expect(flash[:alert]).to eq('No active battle to attack!')
      end
    end

    context 'when it is not the player’s turn' do
      it 'redirects with an alert' do
        battle.update!(turn: 'enemy')
        post :attack_with_item, params: { id: world.id, item_id: item1.id }
        expect(response).to redirect_to(game_path(world))
        expect(flash[:alert]).to eq('It is not your turn!')
      end
    end

    context 'when the enemy is defeated' do
      it 'resolves the battle, awards shards, and redirects' do
        allow_any_instance_of(Battle).to receive(:enemy_data).and_return({ 'health' => 10, 'attack' => 10,
                                                                           'max_health' => 10 })
        post :attack_with_item, params: { id: world.id, item_id: item1.id }
        expect(response).to redirect_to(resolve_battle_world_path(world, outcome: 'win'))
        expect(flash[:notice]).to match(/You defeated the enemy and earned \d+ shards!/)
      end
    end

    context 'when the enemy survives the attack' do
      it 'deals damage to the enemy, toggles turn, and handles enemy turn' do
        battle.enemy_data['health'] = 50
        battle.save!

        post :attack_with_item, params: { id: world.id, item_id: item1.id }

        expect(battle.reload.enemy_data['health']).to be < 50
        expect(battle.reload.turn).to eq(user.id.to_s)
        expect(flash[:notice]).to match(/The enemy attacked you for \d+ damage!/)
      end
    end
  end

  describe 'POST #move' do
    context 'when the player is on the grid' do
      it 'moves the player to an empty cell' do
        post :move, params: { id: world.id, direction: 'down' }

        updated_player_cell = world.cells.find_by(x: 0, y: 0)
        updated_empty_cell = world.cells.find_by(x: 0, y: 1)

        expect(updated_player_cell.content).to eq('empty')
        expect(updated_empty_cell.content).to eq(user.id.to_s)
      end

      it 'moves right and then left' do
        post :move, params: { id: world.id, direction: 'right' }
        post :move, params: { id: world.id, direction: 'left' }

        updated_player_cell = world.cells.find_by(x: 0, y: 0)
        updated_empty_cell = world.cells.find_by(x: 0, y: 1)

        expect(updated_player_cell.content).to eq(user.id.to_s)
        expect(updated_empty_cell.content).to eq('empty')
      end

      it 'handles non-move' do
        post :move, params: { id: world.id, direction: '' }

        updated_player_cell = world.cells.find_by(x: 0, y: 0)
        updated_empty_cell = world.cells.find_by(x: 0, y: 1)

        expect(updated_player_cell.content).to eq(user.id.to_s)
        expect(updated_empty_cell.content).to eq('empty')
      end

      it 'moves the player to a treasure cell and updates shards balance' do
        expect(GameChannel).to receive(:broadcast_to).with(
          world,
          hash_including(html: kind_of(String))
        )
        treasure_cell = world.cells.find_by(x: 1, y: 0)
        expect(treasure_cell).not_to be_nil
        expect(treasure_cell.content).to eq('treasure')

        post :move, params: { id: world.id, direction: 'right' }

        updated_player_cell = world.cells.find_by(x: 0, y: 0)
        updated_treasure_cell = world.cells.find_by(x: 1, y: 0)

        expect(updated_player_cell.content).to eq('empty')
        expect(updated_treasure_cell.content).to eq(user.id.to_s)

        expect(user.reload.shards_balance).to eq(60)
        expect(flash[:notice]).to eq('You found a treasure and earned 10 shards!')
      end

      it 'moves the player to an enemy cell and flashes an alert' do
        post :move, params: { id: world.id, direction: 'down' }
        post :move, params: { id: world.id, direction: 'right' }

        updated_player_cell = world.cells.find_by(x: 0, y: 1)
        updated_enemy_cell = world.cells.find_by(x: 1, y: 1)

        expect(updated_player_cell.content).to eq('empty')
        expect(updated_enemy_cell.content).to eq(user.id.to_s)
      end

      it 'moves the player to an enemy cell and narration is unavailable' do
        allow(ChatGptService).to receive(:call).and_return(nil)
        post :move, params: { id: world.id, direction: 'down' }
        post :move, params: { id: world.id, direction: 'right' }

        updated_player_cell = world.cells.find_by(x: 0, y: 1)
        updated_enemy_cell = world.cells.find_by(x: 1, y: 1)

        expect(updated_player_cell.content).to eq('empty')
        expect(updated_enemy_cell.content).to eq(user.id.to_s)
      end
    end

    context 'when the move is invalid' do
      it 'does not move the player and flashes an alert' do
        post :move, params: { id: world.id, direction: 'up' }

        updated_player_cell = world.cells.find_by(x: 0, y: 0)

        expect(updated_player_cell.content).to eq(user.id.to_s)
        expect(flash[:alert]).to eq('Invalid move!')
      end
    end

    context 'when the world does not belong to the user' do
      let(:other_user) { create(:user) }
      let(:other_world) { create(:world, creator: other_user) }

      before do
        (0..6).each do |x|
          (0..6).each do |y|
            content = if x == 0 && y == 0
                        other_user.id.to_s
                      elsif x == 1 && y == 0
                        'treasure'
                      elsif x == 1 && y == 1
                        'enemy'
                      else
                        'empty'
                      end
            create(:cell, world: other_world, x: x, y: y, content: content)
          end
        end
      end

      it 'redirects to the single_player_path' do
        post :move, params: { id: other_world.id, direction: 'down' }
        expect(response).to redirect_to(single_player_path)
      end

      it 'returns nil when no world is found' do
        allow(World).to receive(:find_by).and_return(nil)
        expect(controller.send(:find_world)).to be_nil
      end

      let(:world3) { create(:world, is_public: true, creator: other_user) }

      it 'returns the world when it is public' do
        allow(World).to receive(:find_by).and_return(world3)
        expect(controller.send(:find_world)).to eq(world3)
      end
    end
  end
end
