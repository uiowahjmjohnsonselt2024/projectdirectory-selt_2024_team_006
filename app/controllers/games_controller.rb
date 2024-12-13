# frozen_string_literal: true

class GamesController < ApplicationController
  before_action :authenticate_user!

  def join
    return redirect_to_single_player('World not found or access denied.') unless world_accessible?

    join_world_or_redirect
  end

  def single_player
    @saved_worlds = World.where(creator_id: current_user.id)
    @multiplayer_worlds = World.where(is_public: true).where.not(creator_id: current_user.id)
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
    return handle_insufficient_shards unless current_user.charge_shards(10)

    @world = build_world
    if @world.save
      @world.broadcast_later(current_user)
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

  def stop_hosting
    # Logic to stop hosting a world
    @world = World.find(params[:id])
    @world.stop_hosting
    flash[:notice] = "Stopped hosting #{@world.name}."
    redirect_to multiplayer_menu_path
  end

  private

  def world_accessible?
    @world = World.find_by(id: params[:id])
    @world && (@world.is_public || @world.creator_id == current_user.id)
  end

  def redirect_to_single_player(message)
    redirect_to single_player_path, alert: message
  end

  def join_world_or_redirect
    @world.place_player(current_user.id)
    redirect_to game_path(@world), notice: 'You have joined the world!'
  rescue StandardError => e
    redirect_to_single_player(e.message)
  end

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
      track_achievement_progress('First World')
      track_achievement_progress('Explorer')
    end
  end

  def track_achievement_progress(name)
    achievement = Achievement.find_by(name: name)
    player_progress = current_user.player_progresses.find_or_create_by(achievement: achievement)
    player_progress.increment!(:current_progress) unless player_progress.completed?
    return unless player_progress.completed? && !player_progress.claimed?

    flash[:success] = "Achievement unlocked: #{name} Claim your reward."
  end

  def handle_insufficient_shards
    flash[:alert] = "You don't have enough shards to create a world. Creating a new world costs 10 shards!"
    redirect_to worlds_path
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
    World.find_by(id: params[:id]).tap do |world|
      return nil unless world && (world.is_public || world.creator_id == current_user.id)
    end
  end

  def world_params
    params.require(:world).permit(:name, :is_public)
  end

  def load_world_details
    @cells = @world.fetch_cells_with_content(current_user)
    @player_in_battle = player_in_battle?
    @current_battle = current_battle
    @user_world_state = user_world_state
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
