class CustomerUser < ActiveRecord::Base
  belongs_to :customer
  belongs_to :user
  validates_presence_of :customer
  validates_presence_of :user

  def self.linked?(customer, user)
    self.exists?(:customer_id => customer, :user_id => user)
  end
end
