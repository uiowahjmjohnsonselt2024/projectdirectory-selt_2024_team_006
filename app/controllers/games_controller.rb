class GamesController < ApplicationController
  before_action :authenticate_user!
  def single_player
    @saved_worlds = World.where(creator_id: current_user.id)  # Fetch saved worlds for the current user
  end

  def new_world
    @world = World.new
  end


  def create
    @world = World.new(world_params)  # Use strong parameters to allow form input
    @world.creator_id = current_user.id
    @world.name = 'New World' if @world.name.blank?  # Set default name if blank

    if @world.save
      redirect_to single_player_path, notice: "World created successfully!"
    else
      render :new_world, alert: "Error creating world."
    end
  end

  def show
    @world = World.find_by(id: params[:id])  # Ensure this matches the world ID and creator
    Rails.logger.info "World object in show action: #{@world.inspect}"  # Log for debugging

    if @world.nil?
      Rails.logger.info "World not found or does not belong to the current user."
      redirect_to single_player_path, alert: "World not found."
    end
  end

  private

  def world_params
    params.require(:world).permit(:name)  # Allow the name attribute (add more if needed)
  end




end

