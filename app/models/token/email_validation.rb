class Token::EmailValidation < Token::Base

  def self.new_for_user!(user)
    token = self.new_with_code
    token.param = {:user_id => user.id}
    token.save!
    token
  end

end
