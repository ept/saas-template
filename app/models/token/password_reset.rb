class Token::PasswordReset < Token::Base

  def self.new_for_user!(user)
    token = self.new_with_code
    token.param = {:user_id => user.id}
    token.expires = 2.weeks.from_now
    token.save!
    token
  end

  def user
    User.find_by_id param[:user_id]
  end

end
