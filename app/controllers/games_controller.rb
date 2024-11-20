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

    destroy_world
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
    return redirect_to single_player_path, alert: 'World not found.' unless @world

    load_world_details
  end

  private

  def destroy_world
    @world.battles.destroy_all
    @world.cells.destroy_all
    @world.user_world_states.destroy_all
    @world.destroy!
  end

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

  def load_world_details
    @cells = fetch_world_cells
    @player_in_battle = player_in_battle?
    @current_battle = current_battle
    @user_world_state = user_world_state
  end

  def fetch_world_cells
    @world.cells.order(:y, :x).map do |cell|
      cell.content = emoji_map(cell.content)
      cell
    end
  end

  def player_in_battle?
    Battle.exists?(player: current_user, world: @world, state: 'active')
  end

  def current_battle
    Battle.find_by(player: current_user, world: @world, state: 'active')
  end

  def user_world_state
    UserWorldState.find_or_create_by(user: current_user, world: @world)
  end
end
