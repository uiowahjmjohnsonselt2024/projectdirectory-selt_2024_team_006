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

  def multiplayer_menu
    # Displays the menu to host or join
  end

  def host
    # Displays the host game menu with available worlds
    @worlds = World.where(creator: current_user)
  end

  def host_world
    # Marks the selected world as hosted
    @world = World.find(params[:id])
    @world.host_game(request.remote_ip)
    flash[:notice] = "Hosting #{@world.name}. Share your IP: #{request.remote_ip}"
    redirect_to host_active_game_path(@world)
  end

  def host_active
    # Displays the currently hosted world and players
    @world = World.find(params[:id])
    @players = @world.users # This assumes you’re storing players in `users`
  end

  def join
    # Displays the join game form
  end

  def join_world
    ip_address = params[:ip_address]
    host_world = World.find_by(host_ip: ip_address, is_hosted: true)

    if host_world.nil?
      flash[:alert] = "No active game found at #{ip_address}."
      redirect_to join_game_path and return
    end

    # Find or create the UserWorldState for this user in the world
    user_world_state = UserWorldState.find_or_create_by(user: current_user, world: host_world) do |state|
      state.health ||= 100 # Set default health for new players
    end

    flash[:notice] = "Joined world: #{host_world.name}."
    redirect_to world_path(host_world)
  end

  def stop_hosting
    # Logic to stop hosting a world
    @world = World.find(params[:id])
    @world.stop_hosting
    flash[:notice] = "Stopped hosting #{@world.name}."
    redirect_to multiplayer_menu_path
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
