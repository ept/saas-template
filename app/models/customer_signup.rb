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
      if not user.valid? and user.errors[:email] then
        user.errors[:email].each do |error|
          errors.add :email, error
        end 
      end
    end

    customer = Customer.new(:subdomain => subdomain)
    if not customer.valid? and customer.errors[:subdomain] then
      customer.errors[:subdomain].each do |error|
        errors.add :subdomain, error
      end
    end

    token = Token::Invitation.find_by_code(invitation_code)
    if not token.valid_for?(customer, user) then
      token.errors.on_base.each do |error|
        errors.add :invitation_code, error
      end
    end
  end

end
