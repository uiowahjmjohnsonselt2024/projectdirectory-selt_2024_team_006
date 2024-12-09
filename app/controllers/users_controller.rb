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
    @player_progress = current_user.player_progresses.index_by(&:achievement_id)
  end

  def claim_achievement
    achievement = Achievement.find(params[:achievement_id])
    progress = current_user.player_progresses.find_by(achievement: achievement)

    if progress.completed? && !progress.claimed?

      current_user.update!(shards_balance: current_user.shards_balance + achievement.reward)

      progress.update!(claimed: true)

      flash[:success] = "Achievement unlocked and reward claimed! You received " + achievement.reward.to_s + " shards."
    else
      flash[:alert] = "Achievement not completed or already claimed."
    end

    redirect_to achievements_path
  end
end
