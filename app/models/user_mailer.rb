class UserMailer < ActionMailer::Base

  helper :application

  def activation(user)
    setup_email(user)
    @subject = 'Please confirm your email address'
    @body[:token] = Token::EmailValidation.new_for_user!(user)
    @body[:customer] = user.signup_customer
  end

  def invitation(customer, user)
    setup_email(user)
    @subject = "#{customer.name} has invited you"
    @body[:token] = Token::Invitation.new_for_customer_user!(customer, user)
    @body[:customer] = customer
  end

  def password_reset(user)
    setup_email user
    @subject = "Reset your password"
    @body[:token] = Token::PasswordReset.new_for_user!(user)
  end
  
  protected
    def setup_email(user)
      @recipients  = "#{user.email}"
      @from        = "support@example.com"
      @sent_on     = Time.now
      @body[:user] = user
    end
end
