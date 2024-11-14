# frozen_string_literal: true

class GamesController < ApplicationController
  before_action :authenticate_user!
  def single_player
    @saved_worlds = World.where(creator_id: current_user.id) # Fetch saved worlds for the current user
  end

  def new_world
    @world = World.new
  end

  def create
    @world = World.new(world_params)
    @world.creator_id = current_user.id
    @world.name = 'New World' if @world.name.blank? # Set default name if blank

    if @world.save
      redirect_to single_player_path, notice: 'World created successfully!'
    else
      render :new_world, alert: 'Error creating world.'
    end
  end

  def show
    @world = find_world

    # Redirect if the world is not found
    if @world.nil?
      redirect_to single_player_path, alert: 'World not found.'
      return
    end

    # Load cells for the grid view, ordered by rows (y) and columns (x)
    @cells = @world.cells.order(:y, :x)
  end

  private

  def find_world
    World.find_by(id: params[:id], creator_id: current_user.id)
  end

  private

  def find_world
    World.find_by(id: params[:id], creator_id: current_user.id)
  end

  def world_params
    params.require(:world).permit(:name)
  end
end
