class CustomerSignup < ActiveRecord::BaseWithoutTable

  column :subdomain, :string
  column :invitation_code, :string

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
