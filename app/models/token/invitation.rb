class Token::Invitation < Token::Base

  # This can be expanded later when we may want to make more specific invitations
  def valid_for?(customer, user)
    if param then
      errors.add_to_base "is restricted."
      valid_token? and false
    else
      valid_token?
    end
  end

end
