class Cupon < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :value, presence: true, numericality: { greater_than: 0 }
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :end_date, presence: true

  scope :active, -> { where(active: true) }
  scope :available, -> { active.where('end_date >= ?', Date.current).where('amount > 0') }

  def expired?
    end_date < Date.current
  end

  def available?
    active? && !expired? && amount > 0
  end

  def apply_discount(original_price)
    if percentage
      discount_amount = (original_price * value / 100.0).round
      [original_price - discount_amount, 0].max
    else
      [original_price - value, 0].max
    end
  end

  def decrement_amount(count)
    new_amount = [amount - count, 0].max
    update!(amount: new_amount, active: new_amount > 0)
  end
end
