class Advertisement < ActiveRecord::Base
  MODULE_NAMES = [['Domovska stranka', 'home_page']]
  
  has_many :advertisement_contents
  accepts_nested_attributes_for :advertisement_contents, :allow_destroy => true

  named_scope :active, proc {|name|  { :conditions => ['active = ? AND module_name = ?', true, name]}}
end