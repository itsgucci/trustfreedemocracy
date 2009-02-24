module UsersHelper
  
  def picture_and_name(user, size = 25)
    if user.nil? || user == :false
		  image_tag('p/default.png', :width => size) + name(user)
    elsif user.name
      image_tag(user.profile_pic.url, :width => size ) + name(user)
    elsif user.facebook_id
  		'<fb:profile-pic uid="' + user.facebook_id + '" width="25px" height="25px" facebook-logo="true"></fb:profile-pic>' + name(user)
  	end
  end
  
  def name(user)
    if user.nil? || user == :false
      "<span class='user_name'>No Body</span>"
    elsif user.name
      "<span class='user_name'>" + h(user.name) + "</span>"
    elsif user.facebook_id
		  '<fb:name uid="' + user.facebook_id + '" capitalize="true"></fb:name>'
		end
  end
  
  def picture(user, size = 25)
    if user.nil? || user == :false
      image_tag('p/default.png', :width => size)
    elsif user.name
      image_tag(user.profile_pic.url, :width => size)
    elsif user.facebook_id
		  '<fb:profile-pic uid="' + user.facebook_id + '" width="25px" height="25px" facebook-logo="true"></fb:profile-pic>'
		end
  end
  
end