# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BattlesHelper, type: :helper do
  let(:user) { create(:user, email: "user#{Time.now.to_i}@example.com", shards_balance: 0) }
  let(:world) { create(:world, creator: user) }

  before do
    allow(ChatGptService).to receive(:call).and_return(
      { 'choices' => [{ 'message' => { 'content' => 'Test response.' } }] }
    )
    allow(ChatGptService).to receive(:generate_image).and_return({ 'data' => [{ 'url' => 'default_image_url' }] })
    allow(helper).to receive(:current_user).and_return(user)
  end

  describe '#player_in_battle?' do
    context 'when the player is in an active battle in the given world' do
      let!(:battle) { create(:battle, player: user, world: world, state: 'active') }

      it 'returns true' do
        expect(helper.player_in_battle?(world)).to be_truthy
      end
    end

    context 'when the player is not in an active battle in the given world' do
      it 'returns false' do
        expect(helper.player_in_battle?(world)).to be_falsey
      end
    end

    context 'when there is a battle but it is not active' do
      let!(:battle) { create(:battle, player: user, world: world, state: 'won') }

      it 'returns false' do
        expect(helper.player_in_battle?(world)).to be_falsey
      end
    end
  end
end
