class CustomerSignup < ActiveRecord::BaseWithoutTable

  column :has_invitation, :integer
  column :subdomain, :string
  column :invitation_code, :string

  def self.from_params_and_session(params, session)
    customer_signup = self.new(params)

    if Token::BetaInvitation.find_by_code(session[:token_code]).valid_token?
      customer_signup.invitation_code ||= session[:token_code]
      customer_signup.has_invitation = 1
    end

    customer_signup
  end

  def validate
    customer = Customer.new(:subdomain => subdomain)
    if !customer.valid? && customer.errors[:subdomain]
      customer.errors[:subdomain].each do |error|
        errors.add :subdomain, error
      end
    end

    token = Token::BetaInvitation.find_by_code(invitation_code)
    unless token.valid_token?
      token.errors.on_base.each do |error|
        errors.add :invitation_code, error
      end
    end
  end

end
