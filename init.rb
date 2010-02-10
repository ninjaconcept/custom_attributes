# Include hook code here

require 'stick/units'
class String
 include Stick::Units
 
end

class U < String
end

require 'acts_as_value_with_unit'

require "custom_attributes"
ActiveRecord::Base.send :include, CustomAttributes::ActsAs