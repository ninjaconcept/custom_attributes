class CustomValueWithUnit < CustomAttribute
  include ActsAsValueWithUnit
  acts_as_value_with_unit :value, :simplify=>true
  
  def validate
    super
    validates_compatible_with_default_unit if validates_compatibility_of_unit?
  end
  
  def validates_compatible_with_default_unit
    error_message = "incompatible with default unit ( example: 1 #{default_unit})"
    self.errors.add(:value, error_message) unless valid_unit?
  end
    
  def default_unit
    @default_unit || customizable_class.default_unit_for_custom_attribute(self.name)
  end
  
  def valid_unit?
    if default_unit.nil? or value.nil? or value.blank? #or !value.is_a?(Stick::Units::Value)
      true
    else
      self.value.unit.compatible_with?(Stick::Units::Unit.new(default_unit)) rescue false
    end
  end
  
  def validates_compatibility_of_unit?
    @validates_unit ||= !default_unit.nil? rescue false
  end
  
  
  #validates_compatible_with_default_unit :value

  # we have to delete the instance from customizable 
  # because we cannot just set the value to blank or nil,
  # due to Stick:Unit format validations
  def update_attribute(id, value)
    if !validates_presence_of? and (value.blank? or value.nil?)
      customizable.remove_custom_attribute(self) if self.customizable
    else
      super
    end
  end
  
end