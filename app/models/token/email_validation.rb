module Token
  class EmailValidation < Base

    def self.new_for_user!(user)
      token = self.new_with_code
      token.param = {:user_id => user.id}
      token.save!
      token
    end

    def handle_redirect
      {:controller => 'users', :action => 'validate_email', :id => code}
    end
  end
end
