# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

RSpec.describe ShardsController, type: :controller do
  let(:user) { create(:user, shards_balance: 0) }
  before { sign_in user }

  before do
    controller.instance_variable_set(:@shards_amount, 10)
    controller.instance_variable_set(:@currency, 'USD')
  end

  describe 'GET #new' do
    it 'initializes instance variables correctly' do
      stub_request(:get, 'https://api.exchangerate-api.com/v4/latest/USD')
        .to_return(
          status: 200,
          body: { rates: { 'USD' => 1.0, 'CAD' => 1.25, 'GBP' => 0.75, 'EUR' => 0.85, 'JPY' => 110.0 } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      get :new

      expect(assigns(:shards_amount)).to eq(0)
      expect(assigns(:card_number)).to eq(nil)
      expect(assigns(:currency)).to eq('USD')
      expect(assigns(:conversion_rate)).to eq(1.0)
      expect(assigns(:supported_currencies)).to eq(%w[USD CAD GBP EUR JPY])
      expect(assigns(:shards_per_usd)).to eq(0.75)
    end
  end

  describe 'POST #create' do
    context 'when valid parameters are provided' do
      let(:valid_card_number) { '1234567890123452' }
      let(:valid_amount) { 10 }
      let(:valid_currency) { 'USD' }

      it 'increments the user\'s shard balance for USD' do
        stub_request(:get, 'https://api.exchangerate-api.com/v4/latest/USD')
          .to_return(
            status: 200,
            body: { rates: { 'USD' => 1.0, 'CAD' => 1.25, 'GBP' => 0.75, 'EUR' => 0.85, 'JPY' => 110.0 } }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        post :create, params: {
          shards_amount: valid_amount,
          card_number: valid_card_number,
          currency: valid_currency
        }

        expected_shards = (valid_amount * 1.0).round
        user.reload
        expect(user.shards_balance).to eq(expected_shards)
        expect(flash[:notice]).to eq("Successfully purchased #{expected_shards} shards!")
      end

      it 'increments the user\'s shard balance for CAD' do
        stub_request(:get, 'https://api.exchangerate-api.com/v4/latest/CAD')
          .to_return(
            status: 200,
            body: { rates: { 'USD' => 0.718, 'CAD' => 1.0, 'GBP' => 0.75, 'EUR' => 0.85, 'JPY' => 110.0 } }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        post :create, params: {
          shards_amount: valid_amount,
          card_number: valid_card_number,
          currency: 'CAD'
        }

        expected_shards = (valid_amount * 0.718).round
        user.reload
        expect(user.shards_balance).to eq(expected_shards)
        expect(flash[:notice]).to eq("Successfully purchased #{expected_shards} shards!")
      end
    end

    context 'when invalid card number is provided' do
      let(:invalid_card_number) { '12345678901234' }
      let(:valid_amount) { 10 }
      let(:valid_currency) { 'USD' }

      it 'does not increment the user\'s shard balance and shows an error' do
        stub_request(:get, 'https://api.exchangerate-api.com/v4/latest/USD')
          .to_return(
            status: 200,
            body: { rates: { 'USD' => 1.0, 'CAD' => 1.25, 'GBP' => 0.75, 'EUR' => 0.85, 'JPY' => 110.0 } }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        post :create, params: {
          shards_amount: valid_amount,
          card_number: invalid_card_number,
          currency: valid_currency
        }

        user.reload
        expect(user.shards_balance).to eq(0)
        expect(flash[:alert]).to include('Card number must be 16 digits long')
      end
    end

    context 'when an invalid shard amount (<= 0) is provided' do
      let(:valid_card_number) { '1234567890123452' }
      let(:invalid_shard_amount) { -1 }
      let(:valid_currency) { 'USD' }

      it 'does not increment the user\'s shard balance and shows an error' do
        stub_request(:get, 'https://api.exchangerate-api.com/v4/latest/USD')
          .to_return(
            status: 200,
            body: { rates: { 'USD' => 1.0, 'CAD' => 1.25, 'GBP' => 0.75, 'EUR' => 0.85, 'JPY' => 110.0 } }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        post :create, params: {
          shards_amount: invalid_shard_amount,
          card_number: valid_card_number,
          currency: valid_currency
        }

        user.reload
        expect(user.shards_balance).to eq(0)
        expect(flash[:alert]).to include('Amount must be greater than 0')
      end
    end
  end

  describe 'POST #fetch_rate' do
    context 'when valid parameters are provided' do
      let(:valid_currency) { 'USD' }

      it 'returns the conversion rate for USD' do
        stub_request(:get, 'https://api.exchangerate-api.com/v4/latest/USD')
          .to_return(
            status: 200,
            body: { rates: { 'USD' => 1.0, 'CAD' => 1.25, 'GBP' => 0.75, 'EUR' => 0.85, 'JPY' => 110.0 } }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        post :fetch_rate, params: { currency: valid_currency }

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['conversion_rate']).to eq(0.75)
      end

      it 'returns the conversion rate for CAD' do
        stub_request(:get, 'https://api.exchangerate-api.com/v4/latest/CAD')
          .to_return(
            status: 200,
            body: { rates: { 'USD' => 0.718, 'CAD' => 1.0, 'GBP' => 0.75, 'EUR' => 0.85, 'JPY' => 110.0 } }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        post :fetch_rate, params: { currency: 'CAD' }

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['conversion_rate']).to eq(0.5385)
      end
    end

    context 'when invalid currency is provided' do
      let(:invalid_currency) { 'CNY' }

      it 'returns an error message' do
        post :fetch_rate, params: { currency: invalid_currency }

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Unsupported currency')
      end
    end

    context 'when API call fails' do
      before do
        stub_request(:get, 'https://api.exchangerate-api.com/v4/latest/GBP')
          .to_return(status: 500, body: 'Internal Server Error')
      end

      it 'returns an error message' do
        post :fetch_rate, params: { currency: 'GBP' }

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Failed to fetch conversion rate')
      end
    end
  end

  describe 'helper methods' do
    context 'when validate_purchase_params is called' do
      it 'returns error messages for invalid card numbers' do
        controller.instance_variable_set(:@card_number, '1232')
        controller.instance_variable_set(:@shards_amount, 10)
        controller.instance_variable_set(:@currency, 'USD')

        errors = controller.send(:validate_purchase_params)

        expect(errors).to include('Card number must be 16 digits long')
      end

      it 'returns error messages for invalid shard amounts' do
        controller.instance_variable_set(:@card_number, '1234567890123452')
        controller.instance_variable_set(:@shards_amount, -1)
        controller.instance_variable_set(:@currency, 'USD')

        errors = controller.send(:validate_purchase_params)

        expect(errors).to include('Amount must be greater than 0')
      end

      it 'returns error messages for invalid currency' do
        controller.instance_variable_set(:@card_number, '1234567890123452')
        controller.instance_variable_set(:@shards_amount, 10)
        controller.instance_variable_set(:@currency, 'AUD')

        errors = controller.send(:validate_purchase_params)

        expect(errors).to include('Unsupported currency')
      end
    end
  end
end
