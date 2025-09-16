class Ticket < ApplicationRecord
  belongs_to :phase, foreign_key: 'phase_id', primary_key: 'id'
  belongs_to :cupon, foreign_key: 'cupon_id', primary_key: 'id'
end
