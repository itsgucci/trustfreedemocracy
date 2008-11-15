class ComiteStage < ActiveRecord::Base
  
  belongs_to :article
  belongs_to :comite
  
end
