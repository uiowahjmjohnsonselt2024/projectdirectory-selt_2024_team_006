# frozen_string_literal: true

module GamesHelper
  def render_cell_content(content)
    case content
    when 'treasure'
      '💰'
    when 'enemy'
      '👾'
    else
      ''
    end
  end
end
