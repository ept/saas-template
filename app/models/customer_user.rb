class CustomerUser < ActiveRecord::Base
  belongs_to :customer
  belongs_to :user
  validates_presence_of :customer
  validates_presence_of :user

  def self.linked?(customer, user)
    self.exists?(:customer_id => customer, :user_id => user, :state => 'active')
  end

  def role
    (permissions == 2) ? "admin" : "user"
  end

  def role=(new_role)
    case new_role.downcase
    when 'user'
      self.permissions = 1
    when 'admin'
      self.permissions = 2
    else
      throw "Unknown role name #{new_role}"
    end
  end

  def grant_admin!
    self.role = 'admin'
    save!
  end

  def revoke_admin!
    self.role = 'user'
    save!
  end

  include AASM

  aasm_column :state
  aasm_initial_state :pending

  aasm_state :pending
  aasm_state :active
  aasm_state :suspended

  aasm_event :activate do
    transitions :from => :pending, :to => :active
  end

  aasm_event :suspend do
    transitions :from => [:pending, :active], :to => :suspended
  end

end
