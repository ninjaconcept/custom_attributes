module CustomAttributes
  module NamedScopes
    SCOPE_SPLIT_REGEX = /_(gt|lt|is|like|begins_with|ends_with)/
    def method_missing(name, *args, &block)
      if custom_attribute_scope?(name)
        scopes = name.to_s.split(SCOPE_SPLIT_REGEX)
        create_custom_attribute_scope(scopes.first, scopes.last)
        result = send(name, *args)
      else
        super
      end
    end
    
    def custom_attribute_scope?(name)
      attr_name = name.to_s.split(SCOPE_SPLIT_REGEX).first
      has_custom_attribute?(attr_name.to_sym)
    end
    
    def create_custom_attribute_scope(name, scope)
      sql = create_custom_attribute_scope_sql(name,scope)
      method_def = <<-EOS
        named_scope :#{name}_#{scope}, lambda { |unit| 
          {:conditions=>[sql, value_with_modifier(unit.is_a?(Stick::Units::Value) ? unit.simplify.value : unit, scope.to_sym)]}
        } 
      EOS
      class_eval(method_def)
    end
    
    def create_custom_attribute_scope_sql(name, scope)
      
      condition = case(scope)
        when /^gt/
          "> ?"
        when /^lt/
          "< ?"
        when /^is/
          "= ?"
        when /^like|^begins_with|^ends_with/
          "like ?"
        else
          raise "undefined scope conditions #{name}_#{scope}"
      end
      
      value_column = case(class_for_custom_attribute(name).name)
        when "CustomString"
          "value_unit"
        when "CustomBoolean"
          "value_boolean"
        else 
          "value_value"
      end
        
      "#{table_name}.id in ( select customizable_id from custom_attributes where custom_attributes.name='#{name}' and custom_attributes.#{value_column} #{condition})"
    end
    
    def value_with_modifier(value, modifier)
      case modifier
      when :like
        "%#{value}%"
      when :begins_with
        "#{value}%"
      when :ends_with
        "%#{value}"
      else
        value
      end
    end
    
    def create_custom_attribute_scope_procedure(name, scope)
      method_def = <<-EOS
        scope_procedure :#{name}_#{scope}, lambda { |unit| 
          value = unit.is_a?(Stick::Units::Value) ? unit.simplify.value : unit 
          custom_attributes_name_is('#{name}').custom_attributes_value_value_#{scope}(value) 
        } 
      EOS
      class_eval(method_def)
    end
  end
end
