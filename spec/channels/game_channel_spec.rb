# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GameChannel, type: :channel do
  let(:world) { create(:world) }
  let(:user) { User.create!(email: 'test4@example.com', password: 'password') }

  before do
    stub_connection current_user: user
    allow_any_instance_of(World).to receive(:generate_background_image).and_wrap_original do |m, *args|
      m.call(*args)
    end
    allow(ChatGptService).to receive(:call).and_return(
      { 'choices' => [{ 'message' => { 'content' => 'Test response.' } }] }
    )
    allow(ChatGptService).to receive(:generate_image).and_return({ 'data' => [{ 'url' => 'default_image_url' }] })
  end

  describe '#subscribed' do
    it 'streams for the specified world' do
      subscribe(world_id: world.id)

      expect(subscription).to be_confirmed
    end

    it 'rejects subscription if world is not found' do
      subscribe(world_id: nil)

      expect(subscription).to be_rejected
    end
  end

  describe '#unsubscribed' do
    it 'stops streaming for the world' do
      subscribe(world_id: world.id)
      expect(subscription).to be_confirmed

      unsubscribe
      expect(subscription.streams).to be_empty
    end
  end
end
