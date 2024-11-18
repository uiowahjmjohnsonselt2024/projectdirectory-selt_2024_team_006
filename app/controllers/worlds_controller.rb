# frozen_string_literal: true

class WorldsController < ApplicationController
  before_action :authenticate_user!

  def move
    @world = find_world
    return redirect_to single_player_path, alert: 'World not found.' unless @world

    player_cell = find_player_cell
    return redirect_to world_path(@world), alert: 'Player not found on grid.' unless player_cell

    process_player_move(player_cell, params[:direction])

    redirect_to world_path(@world)
  end

  private

  def find_world
    World.find_by(id: params[:id], creator_id: current_user.id)
  end

  def find_player_cell
    @world.cells.find_by(content: 'player')
  end

  def process_player_move(player_cell, direction)
    new_position = calculate_new_position(player_cell, direction)

    if valid_position?(new_position)
      move_player(player_cell, new_position)
    else
      flash[:alert] = 'Invalid move!'
    end
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

  def move_player(player_cell, new_position)
    new_cell = @world.cells.find_by(x: new_position[0], y: new_position[1])

    return unless new_cell

    handle_cell_content(new_cell)
    update_cells(player_cell, new_cell)
  end

  def handle_cell_content(cell)
    case cell.content
    when 'treasure'
      award_treasure
    when 'enemy'
      encounter_enemy
    end
  end

  def award_treasure
    current_user.update!(shards_balance: current_user.shards_balance + 10)
    flash[:notice] = 'You found a treasure and earned 10 shards!'
  end

  def encounter_enemy
    flash[:alert] = 'You encountered an enemy! Prepare for battle.'
  end

  def update_cells(player_cell, new_cell)
    player_cell.update!(content: 'empty')
    new_cell.update!(content: 'player')
  end
end
