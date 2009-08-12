class CustomerSignup < ActiveRecord::BaseWithoutTable

  column :subdomain, :string
  column :email, :string
  column :invitation_code, :string
  column :user_id, :integer

  belongs_to :user

  def validate
    user = User.find_by_email email
    if not user
      user = User.new(:email => email)
      if !user.valid? && user.errors[:email]
        user.errors[:email].each do |error|
          errors.add :email, error
        end 
      end
    end

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
