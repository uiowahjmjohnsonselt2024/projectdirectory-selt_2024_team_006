# frozen_string_literal: true

class GamesController < ApplicationController
  before_action :authenticate_user!

  def single_player
    @saved_worlds = World.where(creator_id: current_user.id)
  end

  def new_world
    @world = World.new
  end

  def destroy
    @world = find_world

    if @world.nil?
      redirect_to single_player_path, alert: 'World not found.'
      return
    end

    @world.destroy

    redirect_to single_player_path
  end

  def create
    @world = build_world

    if @world.save
      handle_success
    else
      handle_failure
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

  def build_world
    World.new(world_params).tap do |world|
      world.creator_id = current_user.id
      world.name = 'New World' if world.name.blank?
    end
  end

  def handle_success
    flash[:notice] = 'World created successfully!'
    redirect_to single_player_path
  end

  def handle_failure
    flash[:alert] = 'Error creating world.'
    render :new_world
  end

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
