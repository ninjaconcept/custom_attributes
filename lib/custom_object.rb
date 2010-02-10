class CustomObject < ActiveRecord::Base
  include CustomAttributes
  belongs_to :customizable, :polymorphic => true
end
