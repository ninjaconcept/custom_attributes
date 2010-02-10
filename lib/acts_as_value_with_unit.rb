module ActsAsValueWithUnit
  
  def self.included(base)
    base.class_eval do
      class << self
        attr_reader :acts_as_value_with_unit_attributes
      end
    end
    base.extend(ClassMethods)
  end
                                                            
  module ClassMethods
    
    def acts_as_value_with_unit *args
      options = args.extract_options!
      simplification = options[:simplify] ? ".simplify" : ""
      ids = args
      case 
      when ids.length == 1
        id = ids.first
        class_eval <<-END 
                                                                    
          composed_of :#{id}, :class_name => 'Stick::Units::Value', :mapping => [%w(#{id}_value value), %w(#{id}_unit unit)], 
                                                                    :constructor => Proc.new { |value, unit| Stick::Units::Value.new( value.to_f, unit )#{simplification} },  
                                                                    :converter => Proc.new { |value| Stick::Units::Value.new( value )#{simplification}},
                                                                    :allow_nil => true
                                                                              
          @acts_as_value_with_unit_attributes ||= []
          @acts_as_value_with_unit_attributes = (@acts_as_value_with_unit_attributes << id).uniq
        END
        wrap_with_validation(id)
      when ids.length > 1
        
        ids.each do |id|
          acts_as_value_with_unit id
        end
      end
                                                                                  
    end
      
    def wrap_with_validation *ids  
      case 
      when ids.length == 1
        id = ids.first
        class_eval <<-END 
          alias_method :#{id}_without_validation, :#{id}=
          def #{id}_with_validation= value
             begin
               #{id}_without_validation(value) 
             rescue Exception=>bang
               instance_variable_set("@#{id}".to_sym, value)
             end
          end
          alias_method :#{id}=, :#{id}_with_validation=
        END
      when ids.length > 1
        ids.each do |id|
          wrap_with_validation id
        end
      end
    end
    
  end

  def [](id)
    if id.to_sym == :value
      self.send(id)
    else
      super
    end
  end
  
  def []=(id, value)
    if id.to_sym == :value
      self.send(id, value)
    else
      super
    end
  end
  
  def validate
    validate_acts_as_value_with_unit_attributes(nil, :allow_blank=>true)
    super
  end
  
  def validate_acts_as_value_with_unit_attributes params = nil, options = {}
    options = {:allow_blank=>false}.merge(options)
    unless self.class.acts_as_value_with_unit_attributes.nil?
      self.class.acts_as_value_with_unit_attributes.each do |id|
        value = params ? params[id] : self.send(id)
        validate_acts_as_value_with_unit_attribute(id, value, options)
      end 
    end
  end
  
 
  def validate_acts_as_value_with_unit_attribute id, value, options = {}
    options = {:allow_blank=>false}.merge(options)
    if value.blank?
      if options[:allow_blank]==false
        errors.add( id.to_sym, "si unit cannot be blank")
      end
    else
      unless value.to_s =~ Stick::Units::Regexps::VALUE_REGEXP
        errors.add( id.to_sym, "has invalid format")
      end
    end
    
    return errors.empty?
  end
  

end

