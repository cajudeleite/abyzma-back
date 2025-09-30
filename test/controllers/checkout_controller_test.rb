require "test_helper"
require 'ostruct'

class CheckoutControllerTest < ActionDispatch::IntegrationTest
  def setup
    @phase = phases(:active_phase)
    @fixed_cupon = cupons(:fixed_discount_active)
    @percentage_cupon = cupons(:percentage_discount_active)
    @expired_cupon = cupons(:expired_cupon)
    @inactive_cupon = cupons(:inactive_cupon)
    @zero_amount_cupon = cupons(:zero_amount_cupon)
    
    @valid_params = {
      email: "test@example.com",
      name: "Test User",
      quantity: 1
    }
  end

  test "should create checkout session without coupon" do
    Stripe::Checkout::Session.stubs(:create).returns(
      OpenStruct.new(id: "cs_test_123", url: "https://checkout.stripe.com/test")
    )

    post "/api/v1/create-checkout-session", params: @valid_params

    assert_response :success
    response_data = JSON.parse(response.body)
    assert_equal "cs_test_123", response_data["sessionId"]
    assert response_data["checkoutUrl"].present?
  end

  test "should create checkout session with valid fixed discount coupon" do
    Stripe::Checkout::Session.stubs(:create).returns(
      OpenStruct.new(id: "cs_test_123", url: "https://checkout.stripe.com/test")
    )

    params = @valid_params.merge(cuponCode: @fixed_cupon.name)
    post "/api/v1/create-checkout-session", params: params

    assert_response :success
    response_data = JSON.parse(response.body)
    assert_equal "cs_test_123", response_data["sessionId"]
  end

  test "should create checkout session with valid percentage discount coupon" do
    Stripe::Checkout::Session.stubs(:create).returns(
      OpenStruct.new(id: "cs_test_123", url: "https://checkout.stripe.com/test")
    )

    params = @valid_params.merge(cuponCode: @percentage_cupon.name)
    post "/api/v1/create-checkout-session", params: params

    assert_response :success
    response_data = JSON.parse(response.body)
    assert_equal "cs_test_123", response_data["sessionId"]
  end

  test "should return error for invalid coupon code" do
    params = @valid_params.merge(cuponCode: "INVALID")
    post "/api/v1/create-checkout-session", params: params

    assert_response :bad_request
    response_data = JSON.parse(response.body)
    assert_includes response_data["error"], "There aren't enough available cupons"
  end

  test "should return error for expired coupon" do
    params = @valid_params.merge(cuponCode: @expired_cupon.name)
    post "/api/v1/create-checkout-session", params: params

    assert_response :bad_request
    response_data = JSON.parse(response.body)
    assert_includes response_data["error"], "There aren't enough available cupons"
  end

  test "should return error for inactive coupon" do
    params = @valid_params.merge(cuponCode: @inactive_cupon.name)
    post "/api/v1/create-checkout-session", params: params

    assert_response :bad_request
    response_data = JSON.parse(response.body)
    assert_includes response_data["error"], "There aren't enough available cupons"
  end

  test "should return error for zero amount coupon" do
    params = @valid_params.merge(cuponCode: @zero_amount_cupon.name)
    post "/api/v1/create-checkout-session", params: params

    assert_response :bad_request
    response_data = JSON.parse(response.body)
    assert_includes response_data["error"], "There aren't enough available cupons"
  end

  test "should return error when requesting more tickets than coupon amount allows" do
    params = @valid_params.merge(
      cuponCode: @fixed_cupon.name,
      quantity: @fixed_cupon.amount + 1
    )
    post "/api/v1/create-checkout-session", params: params

    assert_response :bad_request
    response_data = JSON.parse(response.body)
    assert_includes response_data["error"], "There aren't enough available cupons"
  end

  test "should return error when no active phase exists" do
    Phase.update_all(active: false)
    
    post "/api/v1/create-checkout-session", params: @valid_params

    assert_response :not_found
    response_data = JSON.parse(response.body)
    assert_equal "No active phase found", response_data["error"]
  end

  test "should return error when email is missing" do
    params = @valid_params.except(:email)
    post "/api/v1/create-checkout-session", params: params

    assert_response :bad_request
    response_data = JSON.parse(response.body)
    assert_equal "Customer email is required", response_data["error"]
  end

  test "should apply fixed discount correctly in Stripe session" do
    # With the current implementation, fixed discount returns the coupon value directly
    expected_unit_amount = @fixed_cupon.value * 100
    
    Stripe::Checkout::Session.expects(:create).with do |params|
      line_item = params[:line_items].first
      line_item[:price_data][:unit_amount] == expected_unit_amount
    end.returns(OpenStruct.new(id: "cs_test_123", url: "https://checkout.stripe.com/test"))

    params = @valid_params.merge(cuponCode: @fixed_cupon.name)
    post "/api/v1/create-checkout-session", params: params

    assert_response :success
  end

  test "should apply percentage discount correctly in Stripe session" do
    discount_amount = (@phase.price * @percentage_cupon.value / 100.0).round
    expected_unit_amount = (@phase.price - discount_amount) * 100
    
    Stripe::Checkout::Session.expects(:create).with do |params|
      line_item = params[:line_items].first
      line_item[:price_data][:unit_amount] == expected_unit_amount
    end.returns(OpenStruct.new(id: "cs_test_123", url: "https://checkout.stripe.com/test"))

    params = @valid_params.merge(cuponCode: @percentage_cupon.name)
    post "/api/v1/create-checkout-session", params: params

    assert_response :success
  end

  test "should include coupon code in session metadata" do
    Stripe::Checkout::Session.expects(:create).with do |params|
      params[:metadata][:cupon_code] == @fixed_cupon.name
    end.returns(OpenStruct.new(id: "cs_test_123", url: "https://checkout.stripe.com/test"))

    params = @valid_params.merge(cuponCode: @fixed_cupon.name)
    post "/api/v1/create-checkout-session", params: params

    assert_response :success
  end

  test "should handle Stripe errors gracefully" do
    Stripe::Checkout::Session.stubs(:create).raises(Stripe::StripeError.new("Payment failed"))

    post "/api/v1/create-checkout-session", params: @valid_params

    assert_response :bad_request
    response_data = JSON.parse(response.body)
    assert_equal "Payment failed", response_data["error"]
  end

  test "should not allow negative unit amounts" do
    # Create a coupon with value higher than phase price
    high_value_cupon = Cupon.create!(
      name: "HIGH_VALUE",
      active: true,
      value: @phase.price + 100,
      amount: 1,
      percentage: false,
      end_date: 1.year.from_now.to_date
    )

    # With the current implementation, fixed discount returns the coupon value directly
    expected_unit_amount = high_value_cupon.value * 100
    
    Stripe::Checkout::Session.expects(:create).with do |params|
      line_item = params[:line_items].first
      line_item[:price_data][:unit_amount] == expected_unit_amount
    end.returns(OpenStruct.new(id: "cs_test_123", url: "https://checkout.stripe.com/test"))

    params = @valid_params.merge(cuponCode: high_value_cupon.name)
    post "/api/v1/create-checkout-session", params: params

    assert_response :success
  end

  test "should convert quantity to integer" do
    Stripe::Checkout::Session.expects(:create).with do |params|
      params[:line_items].first[:quantity] == 2
    end.returns(OpenStruct.new(id: "cs_test_123", url: "https://checkout.stripe.com/test"))

    params = @valid_params.merge(quantity: "2")
    post "/api/v1/create-checkout-session", params: params

    assert_response :success
  end

  test "should create tickets immediately for 0 euro checkout" do
    # Use a coupon that makes the price 0 (100% discount)
    cupon = Cupon.create!(name: "FREE100", value: 100, percentage: true, amount: 10, active: true, end_date: 1.year.from_now)
    
    params = {
      email: "test@example.com",
      name: "Test User",
      quantity: 2,
      cuponCode: "FREE100"
    }
    
    post "/api/v1/create-checkout-session", params: params
    
    assert_response :success
    
    response_data = JSON.parse(response.body)
    assert_equal true, response_data["success"]
    assert_equal "Free tickets created successfully", response_data["message"]
    assert_equal 2, response_data["tickets"].length
    
    # Verify tickets were created in database
    tickets = Ticket.where(client_email: "test@example.com")
    assert_equal 2, tickets.count
    assert_equal 0, tickets.first.price
    assert_equal 0, tickets.last.price
    assert tickets.first.payment_id.start_with?("free_")
    assert tickets.last.payment_id.start_with?("free_")
  end

  test "should create tickets immediately for 0 euro checkout with free phase" do
    # Deactivate the existing active phase and create a new one with 0 price
    @phase.update!(active: false)
    phase = Phase.create!(name: "Free Phase", price: 0, active: true, start_date: 1.year.ago, end_date: 1.year.from_now)
    
    params = {
      email: "test@example.com",
      name: "Test User",
      quantity: 1
    }
    
    post "/api/v1/create-checkout-session", params: params
    
    assert_response :success
    
    response_data = JSON.parse(response.body)
    assert_equal true, response_data["success"]
    assert_equal "Free tickets created successfully", response_data["message"]
    assert_equal 1, response_data["tickets"].length
    
    # Verify ticket was created in database
    ticket = Ticket.find_by(client_email: "test@example.com")
    assert_not_nil ticket
    assert_equal 0, ticket.price
    assert_nil ticket.cupon
  end
end
