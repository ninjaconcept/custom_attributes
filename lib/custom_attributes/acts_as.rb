module CustomAttributes
  
  module ActsAs

    def self.included(base)
      
      base.extend(ClassMethods)
      
    end
  
    module ClassMethods
      
      def acts_as_custom_attribute_container
        self.send :include, CustomAttributes
      end
      
    end
    
  end
end
