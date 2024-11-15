# frozen_string_literal: true

class GamesController < ApplicationController
  before_action :authenticate_user!

  def single_player
    @saved_worlds = World.where(creator_id: current_user.id)
  end

  def new_world
    @world = World.new
  end

  def create
    @world = World.new(world_params)
    @world.creator_id = current_user.id
    @world.name = 'New World' if @world.name.blank?

    if @world.save
      redirect_to single_player_path, notice: 'World created successfully!'
    else
      render :new_world, alert: 'Error creating world.'
    end
  end

  def show
    @world = find_world

    if @world.nil?
      redirect_to single_player_path, alert: 'World not found.'
      return
    end

    @cells = @world.cells.order(:y, :x).map do |cell|
      cell.content = emoji_map(cell.content)
      cell
    end
  end

  private

  def find_world
    World.find_by(id: params[:id], creator_id: current_user.id)
  end

  def world_params
    params.require(:world).permit(:name)
  end

  def emoji_map(content)
    case content
    when 'player' then '🧍'
    when 'treasure' then '💰'
    when 'enemy' then '👾'
    else ''
    end
  end
end
