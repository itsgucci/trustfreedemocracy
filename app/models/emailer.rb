class Emailer < ActionMailer::Base
  
  def tell_a_friend(email, sub, bod)
    recipients email
    from       "invitations@iwantrealdemocracy.com"
    subject    sub
    body       bod
  end
  
end
