class FacebookPublisher < Facebooker::Rails::Publisher

  def user_profile(user)
    send_as :profile
    
  end

  
end
