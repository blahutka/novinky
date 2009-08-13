class Audio < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :album, :counter_cache => true
  
  has_many :article_audios
  has_many :articles, :through => :article_audios
  
  has_attached_file :data,
                    :url  => "/assets/audios/:id/:style/:basename.:extension",
                    :path => ":rails_root/public/assets/audios/:id/:style/:basename.:extension"
  
end
