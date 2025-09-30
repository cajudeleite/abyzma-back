require "test_helper"

class CuponTest < ActiveSupport::TestCase
  def setup
    @active_fixed_cupon = cupons(:fixed_discount_active)
    @active_percentage_cupon = cupons(:percentage_discount_active)
    @expired_cupon = cupons(:expired_cupon)
    @inactive_cupon = cupons(:inactive_cupon)
    @zero_amount_cupon = cupons(:zero_amount_cupon)
  end

  test "should be valid with valid attributes" do
    cupon = Cupon.new(
      name: "TEST10",
      active: true,
      value: 10,
      amount: 5,
      percentage: false,
      end_date: 1.year.from_now.to_date
    )
    assert cupon.valid?
  end

  test "should require name" do
    cupon = Cupon.new(active: true, value: 10, amount: 5)
    assert_not cupon.valid?
    assert_includes cupon.errors[:name], "can't be blank"
  end

  test "should require value" do
    cupon = Cupon.new(name: "TEST", active: true, amount: 5)
    assert_not cupon.valid?
    assert_includes cupon.errors[:value], "can't be blank"
  end

  test "should require amount" do
    cupon = Cupon.new(name: "TEST", active: true, value: 10)
    assert_not cupon.valid?
    assert_includes cupon.errors[:amount], "can't be blank"
  end

  test "should have unique name" do
    Cupon.create!(name: "UNIQUE", active: true, value: 10, amount: 5, end_date: 1.year.from_now.to_date)
    duplicate_cupon = Cupon.new(name: "UNIQUE", active: true, value: 15, amount: 3, end_date: 1.year.from_now.to_date)
    assert_not duplicate_cupon.valid?
    assert_includes duplicate_cupon.errors[:name], "has already been taken"
  end

  test "should default active to false" do
    cupon = Cupon.new(name: "TEST", value: 10, amount: 5)
    assert_equal false, cupon.active
  end

  test "should default percentage to false" do
    cupon = Cupon.new(name: "TEST", active: true, value: 10, amount: 5)
    assert_equal false, cupon.percentage
  end

  test "active? should return true for active cupons" do
    assert @active_fixed_cupon.active?
    assert @active_percentage_cupon.active?
  end

  test "active? should return false for inactive cupons" do
    assert_not @inactive_cupon.active?
  end

  test "expired? should return true for expired cupons" do
    assert @expired_cupon.expired?
  end

  test "expired? should return false for non-expired cupons" do
    assert_not @active_fixed_cupon.expired?
    assert_not @active_percentage_cupon.expired?
  end

  test "available? should return true for active, non-expired cupons with amount > 0" do
    assert @active_fixed_cupon.available?
    assert @active_percentage_cupon.available?
  end

  test "available? should return false for inactive cupons" do
    assert_not @inactive_cupon.available?
  end

  test "available? should return false for expired cupons" do
    assert_not @expired_cupon.available?
  end

  test "available? should return false for cupons with zero amount" do
    assert_not @zero_amount_cupon.available?
  end

  test "should calculate fixed discount correctly" do
    original_price = 100
    discounted_price = @active_fixed_cupon.apply_discount(original_price)
    assert_equal 90, discounted_price # 100 - 10 = 90
  end

  test "should calculate percentage discount correctly" do
    original_price = 100
    discounted_price = @active_percentage_cupon.apply_discount(original_price)
    assert_equal 80, discounted_price # 100 - (100 * 20/100) = 80
  end

  test "should not allow negative discount amounts" do
    original_price = 5
    discounted_price = @active_fixed_cupon.apply_discount(original_price)
    assert_equal 0, discounted_price
  end

  test "should decrement amount correctly" do
    initial_amount = @active_fixed_cupon.amount
    @active_fixed_cupon.decrement_amount(2)
    assert_equal initial_amount - 2, @active_fixed_cupon.amount
  end

  test "should not allow negative amount after decrement" do
    initial_amount = @active_fixed_cupon.amount
    @active_fixed_cupon.decrement_amount(initial_amount + 5)
    assert_equal 0, @active_fixed_cupon.amount
  end

  test "should deactivate cupon when amount reaches zero" do
    @active_fixed_cupon.decrement_amount(@active_fixed_cupon.amount)
    assert_equal 0, @active_fixed_cupon.amount
    assert_not @active_fixed_cupon.active
  end

  test "scope active should return only active cupons" do
    active_cupons = Cupon.active
    assert_includes active_cupons, @active_fixed_cupon
    assert_includes active_cupons, @active_percentage_cupon
    assert_not_includes active_cupons, @inactive_cupon
  end

  test "scope available should return only available cupons" do
    available_cupons = Cupon.available
    assert_includes available_cupons, @active_fixed_cupon
    assert_includes available_cupons, @active_percentage_cupon
    assert_not_includes available_cupons, @inactive_cupon
    assert_not_includes available_cupons, @expired_cupon
    assert_not_includes available_cupons, @zero_amount_cupon
  end

end
