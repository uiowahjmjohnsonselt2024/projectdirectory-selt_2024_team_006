# frozen_string_literal: true

module BattlesHelper
  def player_in_battle?(world)
    Battle.exists?(player: current_user, world: world, state: 'active')
  end
end
