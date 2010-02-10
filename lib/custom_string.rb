class CustomString < CustomAttribute
     
   def value
     self[:value_unit].to_s
   end
   
   def value=(str)
     self[:value_unit] = str.to_s
   end
   
   def [](id)
     id.to_sym == :value ? self.send(:value_unit) : super
   end
   
   def []=(id, str)
     id.to_sym == :value ? self.send(:value_unit, str) : super
   end
  
  
end