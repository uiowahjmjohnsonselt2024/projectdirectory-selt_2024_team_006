# frozen_string_literal: true

require 'rails_helper'

RSpec.describe World, type: :model do
  let(:creator) { User.create!(email: 'test@example.com', password: 'password') }

  before do
    allow_any_instance_of(World).to receive(:generate_background_image).and_wrap_original do |m, *args|
      m.call(*args)
    end
    allow(ChatGptService).to receive(:call).and_return(
      { 'choices' => [{ 'message' => { 'content' => 'Test response.' } }] }
    )
    allow(ChatGptService).to receive(:generate_image).and_return({ 'data' => [{ 'url' => 'default_image_url' }] })
  end

  describe '#charge_shards' do
    let(:user) { User.create!(email: 'test_user@example.com', password: 'password', shards_balance: 20) }

    context 'when the user has enough shards' do
      it 'deducts the specified amount from the user\'s shards balance' do
        expect { user.charge_shards(10) }.to change { user.reload.shards_balance }.from(20).to(10)
      end

      it 'returns true' do
        result = user.charge_shards(10)
        expect(result).to be true
      end
    end

    context 'when the user does not have enough shards' do
      it 'does not deduct shards from the user\'s balance' do
        expect { user.charge_shards(30) }.not_to(change { user.reload.shards_balance })
      end

      it 'returns false' do
        result = user.charge_shards(30)
        expect(result).to be false
      end
    end
  end

  describe '#generate_background_image' do
    let(:world) { World.create!(name: 'MysticLand', creator: creator) }

    it 'generates and saves a background image URL' do
      expect(world.background_image_url).to eq('default_image_url')
    end
  end

  describe '#generate_lore' do
    let(:world) { World.create!(name: 'MysticLand', creator: creator) }

    it 'generates and saves lore for the world' do
      expect(world.lore).to eq('Test response.')
    end
  end

  describe '#generate_grid' do
    let(:world) { World.create!(creator: creator) }

    it 'creates a 7x7 grid of cells' do
      expect(world.cells.count).to eq(49)
    end

    it 'places the player at position [0, 0]' do
      player_cell = world.cells.find_by(x: 0, y: 0)
      expect(player_cell.content).to eq('player')
    end

    it 'places 5 treasures on the grid' do
      treasure_cells = world.cells.where(content: 'treasure')
      expect(treasure_cells.count).to eq(5)
    end

    it 'places 5 enemies on the grid' do
      enemy_cells = world.cells.where(content: 'enemy')
      expect(enemy_cells.count).to eq(5)
    end

    it 'fills the remaining cells with "empty"' do
      empty_cells = world.cells.where(content: 'empty')
      expected_empty_count = 49 - 1 - 5 - 5
      expect(empty_cells.count).to eq(expected_empty_count)
    end

    it 'does not overlap player, treasure, or enemy positions' do
      all_positions = world.cells.pluck(:content)
      expect(all_positions).to include('player', 'treasure', 'enemy', 'empty')
      expect(all_positions.count('player')).to eq(1)
    end
  end

  describe '#assign_positions' do
    it 'assigns 5 unique treasure positions' do
      (0...7).to_a.product((0...7).to_a)
      world = World.new(creator: creator)
      treasure_positions, enemy_positions = world.send(:assign_positions, 7, [0, 0])

      expect(treasure_positions.count).to eq(5)
      expect(treasure_positions.uniq).to eq(treasure_positions)
      expect(treasure_positions & enemy_positions).to be_empty
    end
  end

  describe '#create_cells' do
    it 'creates a cell for every grid position' do
      world = World.new(creator: creator)
      world.save

      all_positions = (0...7).to_a.product((0...7).to_a)
      cells_positions = world.cells.pluck(:x, :y)

      expect(cells_positions).to match_array(all_positions)
    end
  end
end
