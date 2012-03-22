class AdvertisementContent < ActiveRecord::Base
  belongs_to :advertisement

  named_scope :with_active_date, :conditions => ['active = ? AND (date_start <= ? AND date_finish >= ?)', true, Date.today, Date.today]

  has_attached_file :photo,
                    :url  => "/assets/advertisements/:id/:style/:basename.:extension",
                    :path => ":rails_root/public/assets/advertisements/:id/:style/:basename.:extension",
                    :styles => {:preview => '46x>300', :banner => proc{|v| v.advertisement.banner_size } }

 end