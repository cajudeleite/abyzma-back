class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
  
  # Ensure UUIDs are generated for new records
  before_create :generate_uuid, if: -> { id.blank? }
  
  private
  
  def generate_uuid
    self.id = SecureRandom.uuid
  end
end
