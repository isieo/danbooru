class ModAction < ActiveRecord::Base
  belongs_to :creator, :class_name => "User"
  before_validation :initialize_creator, :on => :create
  
  def initialize_creator
    self.creator_id = CurrentUser.id
  end
end
