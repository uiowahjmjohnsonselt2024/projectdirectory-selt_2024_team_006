# frozen_string_literal: true

require 'net/http'

class ShardsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_supported_currencies, only: %i[new create]

  SUPPORTED_CURRENCIES = %w[USD CAD GBP EUR JPY].freeze
  SHARDS_PER_USD = 1
  CONVERSION_API_URL = 'https://api.exchangerate-api.com/v4/latest/'

  def new
    @shards_amount = params[:shards_amount].to_i || 0
    @card_number = params[:card_number]
    @currency = params[:currency] || 'USD'
    @conversion_rate = fetch_conversion_rate(@currency)
    @supported_currencies = SUPPORTED_CURRENCIES
    @shards_per_usd = SHARDS_PER_USD
  end

  def create
    assign_instance_variables(params)

    errors = validate_purchase_params

    if errors.empty?
      shards_to_add = (@shards_amount * @conversion_rate).round
      complete_purchase(shards_to_add)
    else
      handle_errors(errors)
    end
  end

  def fetch_rate
    currency = params[:currency]

    unless SUPPORTED_CURRENCIES.include?(currency)
      return render json: { error: 'Unsupported currency' }, status: :unprocessable_entity
    end

    conversion_rate = fetch_conversion_rate(currency)

    if conversion_rate
      render json: { conversion_rate: conversion_rate * SHARDS_PER_USD }
    else
      render json: { error: 'Failed to fetch conversion rate' }, status: :unprocessable_entity
    end
  end

  private

  def assign_instance_variables(params)
    @shards_amount = params[:shards_amount].to_i
    @card_number = params[:card_number]
    @currency = params[:currency]
    @conversion_rate = fetch_conversion_rate(@currency)
  end

  def set_supported_currencies
    @supported_currencies = SUPPORTED_CURRENCIES
  end

  def fetch_conversion_rate(currency)
    uri = URI("#{CONVERSION_API_URL}#{currency}")
    response = Net::HTTP.get(uri)
    data = JSON.parse(response)

    data['rates']['USD'] if data['rates'] && data['rates']['USD']
  rescue StandardError
    nil
  end

  def validate_purchase_params
    errors = []
    errors << "Card number can't be blank" if card_number_blank?
    errors << 'Card number must be 16 digits long' if invalid_card_length?
    errors << "Card number must start with '1' and end with '2'" if invalid_card_format?
    errors << 'Amount must be greater than 0' if @shards_amount.to_f <= 0
    errors << 'Unsupported currency' unless SUPPORTED_CURRENCIES.include?(@currency)
    errors
  end

  def complete_purchase(shards_to_add)
    current_user.increment!(:shards_balance, shards_to_add)
    flash[:notice] = "Successfully purchased #{shards_to_add} shards!"
    redirect_to root_path
  end

  def handle_errors(errors)
    flash.now[:alert] = errors.join(', ')
    render :new
  end

  def card_number_blank?
    @card_number.blank?
  end

  def invalid_card_length?
    @card_number.present? && @card_number.length != 16
  end

  def invalid_card_format?
    !(@card_number&.start_with?('1') && @card_number.end_with?('2'))
  end
end
