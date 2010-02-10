# == Schema Information
#
# Table name: custom_attributes
#
#  id                :integer         not null, primary key
#  name              :string(255)
#  customizable_id   :integer
#  customizable_type :string(255)
#  created_at        :datetime
#  updated_at        :datetime
#  value_value       :float
#  value_unit        :string(255)
#

class CustomAttribute < ActiveRecord::Base
  
  belongs_to :customizable, :polymorphic => true
  
  validates_presence_of :value, :if => Proc.new { |ca| 
    ca.validates_presence_of?
  }
  
  def validates_presence_of?
    customizable_class.validates_presence_of_custom_attribute?(self.name)
  end
 
  def customizable_class
    #puts "customizable_class? #{self.inspect}"
    self.customizable && self.customizable.class || self.customizable_type && self.customizable_type.camelcase.constantize
  end
  
end

