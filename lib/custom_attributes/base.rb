module CustomAttributes
  

    def self.included(base)
      base.class_eval do
        has_many :custom_attributes, :as => :customizable, :dependent => :destroy
        validates_associated :custom_attributes
      end
      base.extend(ClassMethods)
      base.extend(CustomAttributes::Validations)
      base.extend(CustomAttributes::NamedScopes)
    end
  
    module ClassMethods
    
      # provides a simple DSL for creating custom_attributes & custom_objects
      # 
      #   has_custom :sizes do 
      #     has_custom :name, :string
      #     has_custom :weight, :unit => 'kg'
      #   end
    
      def has_custom *attributes, &block
        options = attributes.extract_options!
        if block_given?
          has_custom_object attributes.first, options, &block
        else
          if unit = options[:unit]
            has_custom_attributes(*(attributes << options.merge(:class=>CustomValueWithUnit)))
          else
            attr_class_name = "#{attributes.pop}"
            class_name = "Custom#{attr_class_name.camelcase}".constantize
            has_custom_attributes(*(attributes << options.merge(:class=>class_name)))
          end
        end
      end
    
      # creates a dynamic subclass of CustomObject and constantiate it, 
      # with the name derived from the enclosing class and the assiziation name
    
      def has_custom_object association_name, options = {}, &block 
        if block_given?
          class_name = "#{self.name}#{association_name.to_s.singularize.camelcase}"
          create_class(class_name, CustomObject, &block) #unless defined?(class_name.classify.constantize)
          
          has_many association_name, :class_name=>class_name, :as => :customizable, :dependent => :destroy
        else
          raise "no block given, which defines a CustomObject subclass"
        end
      end
    
      def has_custom_attributes *args
         options = args.extract_options!
         args.each do |attr_def|
           has_custom_attribute( attr_def, options )
         end
      end
    
      def has_custom_attribute attr_def, options = {}
      
        custom_attribute_class = options[:class] || CustomAttribute
        custom_attribute_unit = options[:unit] || nil
      
        if attr_def.respond_to?(:keys)    
          attr = { :name => attr_def.keys.first, 
                   :class => attr_def.first[:class] || custom_attribute_class,
                   :unit => attr_def.first[:unit] || custom_attribute_unit }
        else 
          attr = { :name => attr_def, 
                   :class => custom_attribute_class,
                   :unit => custom_attribute_unit }
        end
        @custom_attribute_names = nil
        @custom_attribute_methods = nil
        @custom_attribute_map ||= {}
        @custom_attribute_map[ attr[:name].to_sym ] = attr
      end
    
      def custom_attribute_map
        @custom_attribute_map ||= {}
        ((superclass.custom_attribute_map rescue {}) || {}).merge(@custom_attribute_map) 
      end
    
      def custom_attribute_names 
        @custom_attribute_names ||= custom_attribute_map.keys
      end
    
      def custom_attribute_methods
        @custom_attribute_methods ||= (custom_attribute_names.map{ |key| [key, (key.to_s+"=").to_sym] }.flatten rescue []) 
      end

      def has_custom_attribute? attr_name
        custom_attribute_methods.include?( attr_name ) || (superclass.custom_attribute_methods.include?( attr_name ) rescue false)
      end
    
      def class_for_custom_attribute attr_name
        custom_attribute_map[attr_name.to_sym][:class] 
      end
    
      def custom_attributes_to_validates_presence_of
        (@custom_attributes_to_validates_presence_of || []) + (superclass.custom_attributes_to_validates_presence_of rescue [])
      end
    
      def default_unit_for_custom_attribute attr_name
        custom_attribute_map[attr_name.to_sym][:unit] rescue nil
      end
      
      # callbacks you can overwrite to get specific form layouts
      # todo form_helper
      
      def self.custom_properties
        custom_attribute_names
      end

      def self.sorted_custom_attribute_names
        custom_attribute_names
      end
    
    end
  
    def initialize *args
      super
      attributes = args.extract_options!
      self.class.custom_attribute_names.each do |attr_name|
        value = attributes[attr_name] 
        self.send("#{attr_name}=", value)
      end
    end
  
    def methods *args
      super + self.class.custom_attribute_methods.map(&:to_s)
    end
  
    def respond_to? id
      super || self.class.has_custom_attribute?(id)
    end
  
    def find_custom_attribute_by_name name
      custom_attributes.select { |attr| attr.name.to_s == name.to_s }.compact.first
    end
  
    def find_or_build_custom_attribute_by_name name
      name = name.to_s
      custom_attribute = find_custom_attribute_by_name(name)
      unless custom_attribute
        klass = self.class.class_for_custom_attribute(name)
        customizable_type = "#{self.class}" #self.class.base_class.to_s
        custom_attribute = klass.new(:name=>name, :customizable_id=>self.id, :customizable_type=>customizable_type) 
        custom_attributes << custom_attribute
      end
      custom_attribute
    end
  
    def remove_custom_attribute ca
      remove_custom_attribute_by_name(ca.name) if ca.name
    end
  
    def remove_custom_attribute_by_name name
    
      ca = find_custom_attribute_by_name(name)
    
      CustomAttribute.destroy(ca) if ca
      custom_attributes.delete_if{ |attr| attr.name.to_s == name.to_s }
    
    end
  
    def []=(id, value)
      if self.class.has_custom_attribute?(id.to_sym)
        self.send("#{id}=", value)
      else
        super
      end
    end
  
    def [](id)
      if self.class.has_custom_attribute?(id.to_sym)
        self.send("#{id}")
      else
        super
      end
    end
  
    # def write_attribute(attr_name, value)
    #     if self.class.has_custom_attribute?(attr_name.to_sym)
    #       find_or_build_custom_attribute_by_name(attr_name).write_attribute(:value, value)
    #     else
    #       super
    #     end
    #   end
  
  
    def update_attribute(attr_name, value)
      if self.class.has_custom_attribute?(attr_name.to_sym)
        find_or_build_custom_attribute_by_name(attr_name).update_attribute(:value, value)
      else
        super
      end
    end
  
    def update_attributes(attr_hash)

       custom_attr_hash = attr_hash.select{|key,value| self.class.has_custom_attribute?(key.to_sym)}
       other_attr_hash = attr_hash.reject{|key,value| self.class.has_custom_attribute?(key.to_sym)}
   
       attributes = other_attr_hash
       custom_attr_hash.each do |attr_name, value|
         self.set_custom_attribute_value(attr_name, value) 
       end
  
       if valid?
         custom_attr_hash.each do |attr_name, value|
           update_attribute(attr_name, value)
         end
         super(other_attr_hash)
       end  
   
    end
  
    def save *args
      transaction do
        custom_attributes.each do |ca|
          ca.save if ca.changed?
        end  
        super
      end
    end
    
    def save! *args
      transaction do
        custom_attributes.each do |ca|
          ca.save! if ca.changed?
        end  
        super
      end
    end
  
    def attributes
      super.merge(custom_attributes_hash)
    end
  
    def custom_attributes_hash
      hash = HashWithIndifferentAccess.new 
      custom_attributes.each do |attr|
        hash[attr.name] = attr.value
      end
      hash
    end
  
  
    def method_missing id, *args, &block
      method_name = id.to_s
      case 
      when self.class.has_custom_attribute?(id)
        name = method_name.gsub('=','')
        value = args.length == 1 ? args.first : args
      
        if method_name =~ /=/
          set_custom_attribute_value(name, value)
        else
          get_custom_attribute_value(name)
        end
      when method_name =~ /(.*)_as_(.*)/
        id = $1
        unit_str = $2
        value = self.send(id)
        if value.is_a? Stick::Units::Value
          value.to(unit_str)
        else
          super
        end
      when method_name =~ /(.*)_in_(.*)/
        id = $1
        unit_str = $2
        value = self.send(id)
        if value.is_a? Stick::Units::Value
          value.to(unit_str).value
        else
          super
        end
      else
        super
      end
    end
  
    
    def get_custom_attribute_value(name)
      #@custom_attribute_value ||= {}
      #@custom_attribute_value[name] ||= find_custom_attribute_by_name(name).value rescue nil
      value = find_custom_attribute_by_name(name).value rescue nil
      convert_to_default_unit(name, value)
      # if value.is_a?(Stick::Units::Value)
      #         default_unit = self.class.default_unit_for_custom_attribute(name)
      #         default_unit && value.unit.compatible_with?(Stick::Units::Unit.new(default_unit)) ? value.to(default_unit) : value
      #       else
      #         value
      #       end
    end
  
    def set_custom_attribute_value(name, value)
      #@custom_attribute_value ||= {}
      custom_attribute = find_or_build_custom_attribute_by_name(name)
      custom_attribute.errors.clear
      custom_attribute.value = convert_to_simplified_unit(name, value)
      #@custom_attribute_value[name] = custom_attribute.value
    end
  
    def convert_to_default_unit(name, value)
      if value.is_a?(Stick::Units::Value)
        default_unit = self.class.default_unit_for_custom_attribute(name)
        default_unit && value.unit.compatible_with?(Stick::Units::Unit.new(default_unit)) ? value.to(default_unit) : value
      else
        value
      end
    end
    
    def convert_to_simplified_unit(name, value)
      if value.is_a?(Stick::Units::Value)
        default_unit = self.class.default_unit_for_custom_attribute(name)
        default_unit && value.unit.compatible_with?(Stick::Units::Unit.new(default_unit)) ? value.simplify : value
      else
        value
      end
    end
  
    #validation
  
    def validate
      custom_attributes.each do |attr|   
        unless attr.valid?
          if attr.errors.on(:value)
            attr.errors.on(:value).each do |error_msg|
              errors.add(attr.name.to_sym, error_msg) 
            end 
          end
        end
      end
      super
      clear_errors_on_attribute(:custom_attributes)
    end
  
    def clear_errors_on_attribute id
      errors.instance_eval do
        @errors.delete_if{|key,value| key.to_sym == id}
      end
    end
  
    #instantiation
  
    def self.create_customized_class(*params)
      Class.new(AR) do
        has_custom_attributes *params
      end
    end
  
    def self.constantize_customized_class(class_name, *params)
      Kernel.const_set(class_name, create_customized_class(*params))
    end
  
  
end