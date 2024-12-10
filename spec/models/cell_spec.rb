# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cell, type: :model do
  let(:creator) { User.create!(email: 'test@example.com', password: 'password') }
  let(:world) { create(:world, creator: creator) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(creator)

    allow(ChatGptService).to receive(:call).and_return(
      { 'choices' => [{ 'message' => { 'content' => 'Test response.' } }] }
    )
    allow(ChatGptService).to receive(:generate_image).and_return({ 'data' => [{ 'url' => 'default_image_url' }] })
  end

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
