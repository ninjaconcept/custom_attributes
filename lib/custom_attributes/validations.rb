module CustomAttributes
  module Validations
    def validates_presence_of *attributes
      attributes.each do |attr|
        if custom_attribute_names.include?(attr)
          validates_presence_of_custom_attribute(attr)
        else
          super(attr)
        end
      end
    end
  
    def validates_presence_of_custom_attributes *attributes
      attributes.each do |attr|
        validates_presence_of_custom_attribute(attr)
      end
    end

    def validates_presence_of_custom_attribute attr_name
      @custom_attributes_to_validates_presence_of ||= []
      @custom_attributes_to_validates_presence_of << attr_name.to_sym
    end
  
    def validates_presence_of_custom_attribute? attr_name
      custom_attributes_to_validates_presence_of.include?(attr_name.to_sym)
    end
    
    def validates_default_unit_for_custom_attribute? attr_name
      custom_attribute_to_validates_default_unit_of.include?(attr_name.to_sym)
    end
    
  end
end