# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cell, type: :model do
  let(:world) { create(:world, creator: create(:user)) }

  describe 'validations' do
    it 'is valid with valid attributes' do
      cell = Cell.new(world: world, x: 0, y: 0, content: 'player')
      expect(cell).to be_valid
    end

    it 'is invalid without a world' do
      cell = Cell.new(x: 0, y: 0, content: 'player')
      expect(cell).not_to be_valid
    end

    it 'is invalid without x or y coordinates' do
      cell = Cell.new(world: world, content: 'player')
      expect(cell).not_to be_valid
    end

    it 'is invalid without content' do
      cell = Cell.new(world: world, x: 0, y: 0)
      expect(cell).not_to be_valid
    end
  end
end
