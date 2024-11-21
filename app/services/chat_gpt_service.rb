# frozen_string_literal: true

require 'net/http'
require 'json'

class ChatGptService
  IMAGE_API_KEY = ENV.fetch('IMAGE_API_KEY', nil)
  CHAT_API_KEY = ENV.fetch('CHAT_API_KEY', nil)

  def self.call(messages, model = 'gpt-3.5-turbo', max_tokens = 150)
    uri = URI('https://api.openai.com/v1/chat/completions')
    body = build_chat_request_body(messages, model, max_tokens)
    headers = default_headers(CHAT_API_KEY)

    parse_response(Net::HTTP.post(uri, body.to_json, headers))
  rescue StandardError => e
    log_error('ChatGPT API Error', e)
    default_chat_fallback
  end

  def self.generate_image(description)
    uri = URI('https://api.openai.com/v1/images/generations')
    body = build_image_request_body(description)
    headers = default_headers(IMAGE_API_KEY)

    parse_response(Net::HTTP.post(uri, body.to_json, headers), 'image')
  rescue StandardError => e
    log_error('DALL-E API Error', e)
    default_image_fallback
  end

  def self.build_chat_request_body(messages, model, max_tokens)
    {
      model: model,
      messages: messages,
      max_tokens: max_tokens,
      temperature: 0.7
    }
  end

  def self.build_image_request_body(description)
    {
      prompt: description,
      n: 1,
      size: '1024x1024',
      model: 'dall-e-3'
    }
  end

  def self.default_headers(api_key)
    {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{api_key}"
    }
  end

  def self.parse_response(response, type = 'chat')
    JSON.parse(response.body)
  rescue JSON::ParserError => e
    # :nocov:
    log_error("Error parsing #{type} response", e)
    type == 'chat' ? default_chat_fallback : default_image_fallback
    # :nocov:end
  end

  def self.default_chat_fallback
    { 'choices' => [{ 'message' => { 'content' => 'An error occurred while generating content.' } }] }
  end

  def self.default_image_fallback
    { 'data' => [{ 'url' => 'default_image_url' }] }
  end

  def self.log_error(message, exception)
    Rails.logger.error("#{message}: #{exception.message}")
  end
end
