# frozen_string_literal: true

class WorldsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_world, only: %i[move resolve_battle attack_with_item acknowledge_encounter]

  def move
    @world = find_world
    return redirect_to single_player_path, alert: 'World not found.' unless @world

    player_cell = find_player_cell
    return redirect_to single_player_path, alert: 'Player not found on grid.' unless player_cell

    if process_player_move(player_cell, params[:direction])
      flash[:notice] = 'You moved to an adjacent shard for free!'
    else
      flash[:alert] = 'Invalid move!'
    end

    redirect_to game_path(@world)
  end

  def shard_move
    @world = find_world
    return redirect_to_single_player('World not found.') unless @world

    player_cell = find_player_cell
    return redirect_to_single_player('Player not found on grid.') unless player_cell

    x, y = target_coordinates
    new_cell = find_new_cell([x, y])

    return redirect_to_game('You must acknowledge the encounter first before moving') unless ack_encounter?(player_cell)

    return redirect_to_game('Player is in battle') if player_in_battle?

    return redirect_to_game('Player already at this location') if same_location?(player_cell, x, y)

    return redirect_to_game('Insufficient funds') if insufficient_funds_for_move?

    process_shard_move(player_cell, new_cell)
  end

  def index; end

  def acknowledge_encounter
    cell = @world.cells.find_by(content: current_user.id.to_s)
    if cell
      cell.update!(encounter: nil)
      redirect_to game_path(@world), notice: 'Encounter acknowledged!'
    else
      redirect_to game_path(@world), alert: 'No cell found for the current user.'
    end
  end

  def attack_with_item
    item = find_valid_item
    battle = find_active_battle
    user_world_state = user_world

    return unless item && battle && player_turn?(battle)

    process_attack(item, battle, user_world_state)
  end

  def handle_enemy_turn(battle, user_world_state)
    damage = calculate_damage_battle(battle)
    apply_damage_to_player(user_world_state, damage)

    if player_defeated?(user_world_state)
      handle_loss(battle, damage)
    else
      handle_enemy_attack_success(battle, damage)
    end
  end

  def resolve_battle
    battle = Battle.find_by(player: current_user, world: @world, state: 'active')
    return redirect_to game_path(@world) unless battle

    turn_outcome(params, battle)

    battle.destroy
    redirect_to game_path(@world)
  end

  def player_in_world?
    @world.cells.exists?(content: current_user.id.to_s)
  end

  private

  def redirect_to_single_player(alert_message)
    redirect_to single_player_path, alert: alert_message
  end

  def redirect_to_game(alert_message)
    redirect_to game_path(@world), alert: alert_message
  end

  def insufficient_funds_for_move?
    current_user.shards_balance < 50
  end

  def process_shard_move(player_cell, new_cell)
    distance = calculate_distance(player_cell, new_cell)
    move_cost = calculate_move_cost(distance)
    if insufficient_funds?(move_cost)
      handle_insufficient_funds(distance, move_cost)
    elsif invalid_position?(new_cell)
      handle_invalid_move
    else
      handle_valid_move(player_cell, new_cell, distance, move_cost)
    end

    redirect_to game_path(@world)
  end

  private

  def calculate_move_cost(distance)
    distance * 50
  end

  def insufficient_funds?(cost)
    current_user.shards_balance < cost
  end

  def invalid_position?(new_cell)
    !valid_position?([new_cell.x, new_cell.y])
  end

  def handle_insufficient_funds(distance, cost)
    flash[:alert] = "Insufficient funds for moving #{distance} squares (#{cost} shards required)."
  end

  def handle_invalid_move
    flash[:alert] = 'Invalid move!'
  end

  def handle_valid_move(player_cell, new_cell, distance, move_cost)
    process_move(player_cell, new_cell)
    current_user.decrement!(:shards_balance, move_cost)
    flash[:notice] = "You moved #{distance} squares and were charged #{move_cost} shards."
  end


  def same_location?(player_cell, x_pos, y_pos)
    player_cell.x == x_pos && player_cell.y == y_pos
  end

  def player_in_battle?
    Battle.exists?(player: current_user, world: @world, state: 'active')
  end

  def ack_encounter?(new_cell)
    new_cell.encounter.nil?
  end

  def target_coordinates
    [params[:x].to_i, params[:y].to_i]
  end

  def track_achievement_progress(name)
    achievement = Achievement.find_by(name: name)
    player_progress = current_user.player_progresses.find_or_create_by(achievement: achievement)
    player_progress.increment!(:current_progress) unless player_progress.completed?
    return unless player_progress.completed? && !player_progress.claimed?

    flash[:success] = "Achievement unlocked: #{name} Claim your reward."
  end

  def set_world
    @world = World.find_by(id: params[:id])

    return if @world && (@world.is_public == true || @world.creator_id == current_user.id || player_in_world?)

    redirect_to single_player_path, alert: 'World not found or access denied.'
    nil
  end

  def authorized_to_move?
    @world.creator_id == current_user.id || player_in_world?
  end

  def flash_invalid_move
    flash[:alert] = 'Invalid move!'
  end

  def find_new_cell(position)
    @world.cells.find_by(x: position[0], y: position[1])
  end

  def player_square_occupied?(cell)
    cell.content.match(/^\d+$/)
  end

  def flash_occupied_square
    flash[:alert] = 'That square is occupied by another player!'
  end

  def process_move(player_cell, new_cell)
    handle_cell_content(new_cell)
    update_cells(player_cell, new_cell)
    @world.broadcast_grid(current_user)
  end

  def process_attack(item, battle, user_world_state)
    handle_damage(item, battle)

    if enemy_defeated?(battle)
      handle_victory(battle)
    else
      handle_turn_end(battle, user_world_state)
    end
  end

  def handle_turn_end(battle, user_world_state)
    battle.toggle_turn

    handle_enemy_turn(battle, user_world_state)
  end

  def handle_damage(item, battle)
    damage = rand(item.damage - 5..item.damage + 5)
    damage = [damage, 0].max

    battle.enemy_data['health'] -= damage
    battle.enemy_data['health'] = [0, battle.enemy_data['health']].max
    battle.save!
  end

  def enemy_defeated?(battle)
    battle.enemy_data['health'] <= 0
  end

  def handle_victory(battle)
    battle.resolve('won')
    track_achievement_progress('First Kill')
    track_achievement_progress('Slayer')
    shards = award_victory_shards(battle)
    flash[:notice] = "You defeated the enemy and earned #{shards} shards!"

    @world.broadcast_grid(current_user)

    redirect_to resolve_battle_world_path(@world, outcome: 'win')
  end

  def award_victory_shards(battle)
    shards = calculate_shard_drop(battle.enemy_data)
    current_user.update!(shards_balance: current_user.shards_balance + shards)
    shards
  end

  def user_world
    UserWorldState.find_by(user: current_user, world: @world)
  end

  def find_valid_item
    item = current_user.items.find_by(id: params[:item_id])
    unless item
      redirect_to game_path(@world), alert: 'Invalid item!'
      return nil
    end
    item
  end

  def find_active_battle
    battle = Battle.find_by(player: current_user, world: @world, state: 'active')
    unless battle
      redirect_to game_path(@world), alert: 'No active battle to attack!'
      return nil
    end
    battle
  end

  def player_turn?(battle)
    return true if battle.turn == current_user.id.to_s

    redirect_to game_path(@world), alert: 'It is not your turn!'
    false
  end

  def turn_outcome(params, battle)
    if params[:outcome] == 'win'
      shards = calculate_shard_drop(battle.enemy_data)
      current_user.update!(shards_balance: current_user.shards_balance + shards)
      flash[:notice] = "You defeated the enemy and earned #{shards} shards!"
    elsif params[:outcome] == 'lose'
      flash[:alert] = 'You lost the battle!'
    end
  end

  def find_world
    World.find_by(id: params[:id]).tap do |world|
      return nil unless world && (world.is_public == true || world.creator_id == current_user.id)
    end
  end

  def find_player_cell
    @world.cells.find_by(content: user_id_str)
  end

  def process_player_move(player_cell, direction)
    return unless authorized_to_move?

    new_position = calculate_new_position(player_cell, direction)
    return flash_invalid_move unless valid_position?(new_position)

    new_cell = find_new_cell(new_position)
    return flash_occupied_square if player_square_occupied?(new_cell)

    process_move(player_cell, new_cell)
  end

  def calculate_new_position(player_cell, direction)
    case direction
    when 'up' then [player_cell.x, player_cell.y - 1]
    when 'down' then [player_cell.x, player_cell.y + 1]
    when 'left' then [player_cell.x - 1, player_cell.y]
    when 'right' then [player_cell.x + 1, player_cell.y]
    else
      [player_cell.x, player_cell.y]
    end
  end

  def valid_position?(position)
    position.all? { |coord| coord.between?(0, 6) }
  end

  def handle_cell_content(cell)
    case cell.content
    when 'treasure'
      award_treasure
    when 'enemy'
      start_battle(cell)
    end

    @world.broadcast_grid(current_user)
  end

  def start_battle(cell)
    existing_battle = Battle.find_by(player: current_user, world: @world, state: 'active')
    return if existing_battle

    enemy_stats = generate_enemy_stats
    messages = chat_gpt_message(enemy_stats)
    narration = ChatGptService.call(messages)
    narration_text = extract_narration_text(narration)
    create_base_battle(narration_text, cell, enemy_stats)
    cell.update!(content: 'battle')
  end

  def chat_gpt_message(enemy_stats)
    [
      {
        role: 'system',
        content: "You are a narrator for a text-based RPG game.
                  The player has encountered an enemy in a mysterious world.
                  Describe the enemy with #{enemy_stats[:health]}
                  health and #{enemy_stats[:attack]} attack power in a vivid and exciting way.
                  strictly limit the response to 30 words and no more."
      }
    ]
  end

  def create_base_battle(narration_text, cell, enemy_stats)
    Battle.create!(
      world: @world,
      cell: cell,
      player: current_user,
      enemy_data: enemy_stats.merge('narration' => narration_text),
      state: 'active',
      turn: current_user.id.to_s
    )
  end

  def extract_narration_text(narration)
    if narration && narration['choices'] && narration['choices'][0] &&
       narration['choices'][0]['message']
      narration['choices'][0]['message']['content'].strip
    else
      'An error occurred while generating the narration.'
    end
  end

  def generate_enemy_stats
    max_health = rand(50..150)
    {
      health: max_health,
      max_health: max_health,
      attack: rand(5..20),
      defense: rand(3..10)
    }
  end

  def award_treasure
    current_user.update!(shards_balance: current_user.shards_balance + 10)
    flash[:notice] = 'You found a treasure and earned 10 shards!'
  end

  def update_cells(player_cell, new_cell)
    player_cell.update!(content: 'empty')
    new_cell.update!(content: current_user.id)
  end

  def calculate_shard_drop(enemy_data)
    max_health = enemy_data['max_health']
    attack = enemy_data['attack']

    # heuristic: higher health and damage yield more shards
    base_shards = (max_health / 10) + (attack / 2)

    rand(base_shards..(base_shards * 1.5)).to_i
  end

  def calculate_damage_battle(battle)
    rand(battle.enemy_data['attack'] - 5..battle.enemy_data['attack'] + 5).clamp(0, Float::INFINITY)
  end

  def apply_damage_to_player(user_world_state, damage)
    user_world_state.health -= damage
    user_world_state.health = [0, user_world_state.health].max
    user_world_state.save!
  end

  def player_defeated?(user_world_state)
    user_world_state.health <= 0
  end

  def handle_loss(battle, damage)
    resolve_battle_loss(battle)
    destroy_world
    flash[:alert] = "The enemy defeated you! You took #{damage} damage and your world has been destroyed. Game over!"

    @world.broadcast_grid(current_user)

    redirect_to single_player_path
  end

  def handle_enemy_attack_success(battle, damage)
    battle.toggle_turn
    flash[:notice] = "The enemy attacked you for #{damage} damage! It is now your turn."
    redirect_to game_path(@world)
  end

  def resolve_battle_loss(battle)
    battle.resolve('lost')
  end

  def destroy_world
    @world.battles.destroy_all
    @world.cells.destroy_all
    @world.user_world_states.destroy_all
    @world.destroy!
  end

  def user_id_str
    current_user.id.to_s
  end

  def calculate_distance(player_cell, new_cell)
    distance = (player_cell.x - new_cell.x).abs + (player_cell.y - new_cell.y).abs
    distance <= 1 ? 0 : distance
  end
end
