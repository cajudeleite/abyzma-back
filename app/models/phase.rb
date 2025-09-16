class Phase < ApplicationRecord
  has_many :tickets, foreign_key: 'phase_id', primary_key: 'id'
end
