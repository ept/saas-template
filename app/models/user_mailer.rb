class UserMailer < ActionMailer::Base
  def signup_notification(user)
    setup_email(user)
    @subject    = 'Please activate your new account'
  
    @body[:url]  = "http://YOURSITE/activate/#{user.activation_code}"
  
  end
  
  def activation(user)
    setup_email(user)
    token = Token::EmailValidation.new_for_user!(user)
    @subject    = 'Please confirm your email address'
    @body[:url]  = "http://go-test.it/users/validate_email/#{token.code}"
  end

  def invitation(customer, user)
    setup_email(user)
    token = Token::Invitation.new_for_customer_user!(customer, user)
    @subject = "#{customer.name} on Go Test It"
    @body[:url] = "http://#{customer.subdomain}.go-test.it/users/accept_invitation/#{token.code}"
    @body[:customer] = customer
  end
  
  protected
    def setup_email(user)
      @recipients  = "#{user.email}"
      @from        = "support@go-test.it"
      @sent_on     = Time.now
      @body[:user] = user
    end
end
