# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Battle, type: :model do
  let(:creator) { User.create!(email: 'test@example.com', password: 'password') }
  let(:world) do
    World.create!(name: 'Test World', creator: creator)
  end
  let(:cell) { Cell.create!(world: world, x: 0, y: 0, content: 'empty') }
  let(:player) { User.create!(email: 'player@example.com', password: 'password') }
  let(:battle) { Battle.create!(world: world, cell: cell, player: player, state: 'active', turn: 'player') }

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(creator)

    allow(ChatGptService).to receive(:call).and_return(
      { 'choices' => [{ 'message' => { 'content' => 'Test response.' } }] }
    )
    allow(ChatGptService).to receive(:generate_image).and_return({ 'data' => [{ 'url' => 'default_image_url' }] })
  end

  describe 'validations' do
    it 'is valid with a valid state' do
      expect(battle).to be_valid
    end

    it 'is invalid with an invalid state' do
      battle.state = 'invalid_state'
      expect(battle).not_to be_valid
      expect(battle.errors[:state]).to include('is not included in the list')
    end
  end

  describe '#resolve' do
    it 'updates the battle state to the provided result' do
      battle.resolve('won')
      expect(battle.state).to eq('won')
    end

    it 'raises an error for an invalid result' do
      expect { battle.resolve('invalid_state') }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe '#toggle_turn' do
    it 'toggles the turn from player to enemy' do
      battle.toggle_turn
      expect(battle.turn).to eq(player.id.to_s)
    end

    it 'toggles the turn from enemy to player' do
      battle.update!(turn: 'enemy')
      battle.toggle_turn
      expect(battle.turn).to eq(player.id.to_s)
    end
  end

  describe 'associations' do
    it 'belongs to a world' do
      expect(battle.world).to eq(world)
    end

    it 'belongs to a cell' do
      expect(battle.cell).to eq(cell)
    end

    it 'belongs to a player' do
      expect(battle.player).to eq(player)
    end
  end
end
