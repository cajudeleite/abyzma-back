class Cupon < ApplicationRecord
  # Disable Single Table Inheritance since we have a 'type' column for business logic
  self.inheritance_column = nil
end
