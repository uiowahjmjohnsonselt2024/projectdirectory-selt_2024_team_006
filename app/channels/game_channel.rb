# frozen_string_literal: true

class GameChannel < ApplicationCable::Channel
  def subscribed
    if params[:world_id].present?
      stream_for World.find(params[:world_id])
    else
      reject
    end
  end

  def unsubscribed; end
end
