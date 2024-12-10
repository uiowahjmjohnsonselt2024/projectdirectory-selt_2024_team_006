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
    achievement = find_achievement
    progress = find_player_progress(achievement)

    if can_claim_reward?(progress)
      process_claim(achievement, progress)
      flash[:success] = success_message(achievement.reward)
    else
      flash[:alert] = 'Achievement not completed or already claimed.'
    end

    redirect_to achievements_path
  end

  private

  def find_achievement
    Achievement.find(params[:achievement_id])
  end

  def find_player_progress(achievement)
    current_user.player_progresses.find_by(achievement: achievement)
  end

  def can_claim_reward?(progress)
    progress.completed? && !progress.claimed?
  end

  def process_claim(achievement, progress)
    current_user.update!(shards_balance: current_user.shards_balance + achievement.reward)
    progress.update!(claimed: true)
  end

  def success_message(reward)
    "Achievement unlocked and reward claimed! You received #{reward} shards."
  end
end
