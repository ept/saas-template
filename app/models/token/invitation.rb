module Token
  class Invitation < Base

    def self.new_for_customer_user!(customer, user)
      token = self.new_with_code
      token.param = {:subdomain => customer.subdomain, :email => user.email}
      token.save!
      token
    end

    def valid_for?(customer, user)
      if param && (param[:subdomain] && !param[:subdomain] == customer.subdomain || param[:email] && !param[:email] == user.email)
        errors.add_to_base "is restricted"
        false
      else
        valid_token?
      end
    end

    def handle_redirect
      {:controller => 'users', :action => 'accept_invitation', :id => code}
    end
  end
end
