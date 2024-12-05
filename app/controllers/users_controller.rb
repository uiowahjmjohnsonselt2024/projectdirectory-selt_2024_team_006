# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
    @inventory_items = @user.items
  end

  def achievements
    @user = current_user
    @achievements = Achievement.all
  end

  def claim_achievement
    achievement = Achievement.find(params[:achievement_id])
    progress = current_user.player_progresses.find_by(achievement: achievement)

    if progress.completed? && !progress.claimed?

      current_user.update!(shards_balance: current_user.shards_balance + 50)

      progress.update!(claimed: true)

      flash[:success] = "Achievement unlocked and reward claimed! You received 50 shards."
    else
      flash[:alert] = "Achievement not completed or already claimed."
    end

    redirect_to achievements_path
  end
end
