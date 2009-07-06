class UserMailer < ActionMailer::Base
  def signup_notification(user)
    setup_email(user)
    @subject    = 'Please activate your new account'
  
    @body[:url]  = "http://YOURSITE/activate/#{user.activation_code}"
  
  end
  
  def activation(user)
    setup_email(user)
    @body[:token] = Token::EmailValidation.new_for_user!(user)
    @subject    = 'Please confirm your email address'
  end

  def invitation(customer, user)
    setup_email(user)
    @body[:token] = Token::Invitation.new_for_customer_user!(customer, user)
    @subject = "#{customer.name} on Go Test It"
    @body[:customer] = customer
  end

  def password_reset(user)
    setup_email user
    @body[:token] = Token::PasswordReset.new_for_user!(user)
    @subject = "Reset your Go Test It password"
  end
  
  protected
    def setup_email(user)
      @recipients  = "#{user.email}"
      @from        = "support@go-test.it"
      @sent_on     = Time.now
      @body[:user] = user
    end
end
