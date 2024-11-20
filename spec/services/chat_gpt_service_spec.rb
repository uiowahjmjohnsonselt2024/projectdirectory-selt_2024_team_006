# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

RSpec.describe ChatGptService, type: :service do
  let(:chat_api_key) { 'test_chat_api_key' }
  let(:image_api_key) { 'test_image_api_key' }
  let(:chat_api_url) { 'https://api.openai.com/v1/chat/completions' }
  let(:image_api_url) { 'https://api.openai.com/v1/images/generations' }

  before do
    allow(ENV).to receive(:[]).with('CHAT_API_KEY').and_return(chat_api_key)
    allow(ENV).to receive(:[]).with('IMAGE_API_KEY').and_return(image_api_key)
  end

  describe '.call' do
    let(:messages) { [{ role: 'system', content: 'Test message.' }] }
    let(:mock_response) do
      {
        'choices' => [
          { 'message' => { 'content' => 'Test response.' } }
        ]
      }.to_json
    end

    before do
      stub_request(:post, chat_api_url)
        .with(
          body: {
            model: 'gpt-3.5-turbo',
            messages: messages,
            max_tokens: 150,
            temperature: 0.7
          }.to_json
        )
        .to_return(status: 200, body: mock_response, headers: { 'Content-Type' => 'application/json' })
    end

    it 'sends a POST request to the ChatGPT API and returns the response' do
      result = described_class.call(messages)
      expect(result).to eq(JSON.parse(mock_response))
    end

    it 'logs an error and returns a default response on failure' do
      stub_request(:post, chat_api_url).to_raise(StandardError.new('API Error'))
      expect(Rails.logger).to receive(:error).with('ChatGPT API Error: API Error')
      result = described_class.call(messages)
      expect(result['choices'][0]['message']['content']).to eq('An error occurred while generating content.')
    end
  end

  describe '.generate_image' do
    let(:description) { 'Generate a test image' }
    let(:mock_image_response) do
      {
        'data' => [
          { 'url' => 'http://example.com/test_image.png' }
        ]
      }.to_json
    end

    before do
      stub_request(:post, image_api_url)
        .with(
          body: {
            prompt: description,
            n: 1,
            size: '1024x1024',
            model: 'dall-e-3'
          }.to_json
        )
        .to_return(status: 200, body: mock_image_response, headers: { 'Content-Type' => 'application/json' })
    end

    it 'sends a POST request to the DALL-E API and returns the response' do
      result = described_class.generate_image(description)
      expect(result).to eq(JSON.parse(mock_image_response))
    end

    it 'logs an error and returns a default response on failure' do
      stub_request(:post, image_api_url).to_raise(StandardError.new('Image API Error'))
      expect(Rails.logger).to receive(:error).with('DALL-E API Error: Image API Error')
      result = described_class.generate_image(description)
      expect(result['data'][0]['url']).to eq('default_image_url')
    end
  end
end
