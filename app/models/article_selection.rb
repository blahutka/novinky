class ArticleSelection < ActiveRecord::Base
  
  belongs_to :article
  belongs_to :section
  
end
