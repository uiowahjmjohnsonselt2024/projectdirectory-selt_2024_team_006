# frozen_string_literal: true

require 'chat_gpt_service'
require 'concurrent'

class World < ApplicationRecord
  belongs_to :creator, class_name: 'User', foreign_key: 'creator_id'
  has_many :cells, dependent: :destroy
  has_many :battles, dependent: :destroy
  has_many :user_world_states, dependent: :destroy
  has_many :users, through: :user_world_states

  after_create :generate_grid, :generate_lore, :generate_background_image

  validates :creator, presence: true

  # Scopes for multiplayer
  scope :hosted, -> { where(is_hosted: true) }

  # Utility methods for multiplayer
  def host_game(ip_address)
    update!(is_hosted: true, host_ip: ip_address)
  end

  def stop_hosting
    update!(is_hosted: false, host_ip: nil)
  end

  def hosted_by?(user)
    creator == user && is_hosted
  end

  private

  def generate_lore
    messages = chat_messages

    response = ChatGptService.call(messages)
    self.lore = response['choices'][0]['message']['content'].strip
    save!
  end

  def generate_background_image
    return if lore.blank?

    Concurrent::Future.execute do
      prompt = build_image_prompt
      response = fetch_image_from_service(prompt)
      handle_image_response(response)
    rescue StandardError => e
      # :nocov:
      handle_standard_error(e)
      # :nocov:end
    end
  end

  def handle_image_response(response)
    if valid_image_response?(response)
      process_valid_image_response(response)
    else
      # :nocov:
      handle_image_generation_error(response)
      # :nocov:end
    end
  end

  def generate_grid
    grid_size = 7
    player_position = [0, 0]
    treasure_positions, enemy_positions = assign_positions(grid_size, player_position)

    create_cells(grid_size, player_position, treasure_positions, enemy_positions)
  end

  def assign_positions(grid_size, player_position)
    all_positions = (0...grid_size).to_a.product((0...grid_size).to_a)
    available_positions = all_positions - [player_position]

    treasure_positions = available_positions.sample(5)
    available_positions -= treasure_positions

    enemy_positions = available_positions.sample(5)
    [treasure_positions, enemy_positions]
  end

  def create_cells(grid_size, player_position, treasure_positions, enemy_positions)
    (0...grid_size).each do |x|
      (0...grid_size).each do |y|
        cells.create!(x: x, y: y, content: cell_content(x, y, player_position, treasure_positions, enemy_positions))
      end
    end
  end

  def cell_content(x_pos, y_pos, player_position, treasure_positions, enemy_positions)
    position = [x_pos, y_pos]
    return 'player' if position == player_position
    return 'treasure' if treasure_positions.include?(position)
    return 'enemy' if enemy_positions.include?(position)

    'empty'
  end

  def build_image_prompt
    "Generate an 8 bit fantasy world background based on the lore: '#{lore}' (do not include any text in the image)"
  end

  def fetch_image_from_service(prompt)
    ChatGptService.generate_image(prompt)
  end

  def valid_image_response?(response)
    response['data'].present? && response['data'][0].present? && response['data'][0]['url'].present?
  end

  def process_valid_image_response(response)
    self.background_image_url = response['data'][0]['url']
    update!(background_image_url: response['data'][0]['url'])
  end

  # :nocov:
  def handle_image_generation_error(response)
    Rails.logger.error("Failed to generate background image: #{response['error']}")
    self.background_image_url = 'dungeon_bg.png'
    save!
  end
  # :nocov:end

  # :nocov:
  def handle_standard_error(exception)
    Rails.logger.error("Error during background image generation: #{exception.message}")
    self.background_image_url = 'dungeon_bg.png'
    save!
  end
  # :nocov:end

  def chat_messages
    [
      {
        role: 'system',
        content: "You are a world creator for a fantasy RPG.
                Create a short backstory for a world named '#{name}'.
                Include details about its history, the people who lived there, and why it has become mysterious."
      }
    ]
  end
end
