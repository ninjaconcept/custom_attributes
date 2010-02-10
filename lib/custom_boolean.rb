class CustomBoolean < CustomAttribute
     
   def value
     self[:value_boolean]
   end
   
   def value=(bool)
     self[:value_boolean] = bool
   end
   
   def [](id)
     id.to_sym == :value ? self.send(:value_boolean) : super
   end
   
   def []=(id, bool)
     id.to_sym == :value ? self.send(:value_boolean, bool) : super
   end
  
  
end