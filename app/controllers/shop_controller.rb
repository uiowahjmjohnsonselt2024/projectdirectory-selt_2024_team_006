# frozen_string_literal: true

class ShopController < ApplicationController
  before_action :authenticate_user!

  def index
    @items = Item.where.not(name: 'Basic Dagger')
  end

  def buy
    item = Item.find(params[:id])

    user_item = current_user.user_items.find_by(item: item)

    if user_item
      sell_item(user_item)
    else
      buy_new_item(item)
    end

    redirect_to shop_index_path
  end

  private

  def buy_new_item(item)
    if current_user.shards_balance >= item.price
      current_user.decrement!(:shards_balance, item.price)

      current_user.user_items.create(item: item)

      flash[:notice] = "Successfully bought #{item.name}!"
    else
      flash[:alert] = 'Not enough shards!'
    end
  end

  def sell_item(user_item)
    refund_amount = (user_item.item.price * 0.75).round
    current_user.increment!(:shards_balance, refund_amount)

    user_item.destroy

    flash[:notice] = "Successfully sold #{user_item.item.name} for #{refund_amount} Shards!"
  end
end
