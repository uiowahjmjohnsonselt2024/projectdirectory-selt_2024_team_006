# frozen_string_literal: true

class WorldsController < ApplicationController
  before_action :authenticate_user!

  def move
    @world = find_world
    player_cell = @world.cells.find_by(content: 'player')

    redirect_to world_path(@world), alert: 'Player not found on grid.' and return unless player_cell

    new_position = calculate_new_position(player_cell, params[:direction])

    if valid_position?(new_position)
      handle_move(player_cell, new_position)
    else
      flash[:alert] = 'Invalid move!'
    end

    redirect_to world_path(@world)
  end

  private

  def find_world
    World.find_by(id: params[:id], creator_id: current_user.id)
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

  def handle_move(player_cell, new_position)
    new_cell = @world.cells.find_by(x: new_position[0], y: new_position[1])

    return unless new_cell

    handle_cell_content(new_cell)
    update_cells(player_cell, new_cell)
  end

  def handle_cell_content(cell)
    case cell.content
    when 'treasure'
      current_user.update(shards_balance: current_user.shards_balance + 10)
      flash[:notice] = 'You found a treasure and earned 10 shards!'
    when 'enemy'
      flash[:alert] = 'You encountered an enemy! Prepare for battle.'
    end
  end

  def update_cells(player_cell, new_cell)
    player_cell.update(content: 'empty')
    new_cell.update(content: 'player')
  end
end
