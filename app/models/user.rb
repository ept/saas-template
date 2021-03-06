require 'digest/sha1'

class User < ActiveRecord::Base

  class UserSuspended < StandardError; end

  has_many :customers, :through => :customer_users
  has_many :customer_users

  include Authentication
  include Authentication::ByPassword
  include Authentication::ByCookieToken
  include Authorization::AasmRoles

  aasm_initial_state :initial => :passive

  validates_format_of       :name,     :with => Authentication.name_regex,  :message => Authentication.bad_name_message, :allow_nil => true
  validates_length_of       :name,     :maximum => 100

  validates_presence_of     :email
  validates_length_of       :email,    :within => 6..100 #r@a.wk
  validates_uniqueness_of   :email
  validates_format_of       :email,    :with => Authentication.email_regex, :message => Authentication.bad_email_message

  # Only make non-critical attributes attr_accessible (which are ok to be edited by customer admins)
  attr_accessible :email, :name, :time_zone, :marketing_opt_in

  # Temporary field for the user's customer, used during sign-up process
  attr_accessor :signup_customer

  before_save :activate_when_password_set

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil,
  # or throws +UserSuspended+ if the account is suspended.
  def self.authenticate(email, password)
    return nil if email.blank? || password.blank?
    conditions = {:email => email.downcase}
    u = find_in_state :first, :active,  :conditions => conditions
    u = find_in_state :first, :pending, :conditions => conditions if u.nil?
    if u.nil?
      if find_in_state :first, :suspended, :conditions => conditions
        raise UserSuspended, "Your account has been suspended. Please contact support."
      end
    end
    u && u.authenticated?(password) ? u : nil
  end

  # This is a method to make creating new users easy while we don't have a signup process
  def self.create_for_demo(email, password)
    user = User.new(:email => email, :name => email[/^[^@]+/])
    user.password = password
    user.password_confirmation = password
    user.is_admin = 0
    user.state = :active
    user.save!
    user
  end

  def email=(value)
    if value
      value = value.downcase
      write_attribute :email, value
      self.name = (value[/^[^@]+/].split(/[\._\-\s]/).each{|w| w.capitalize! }.join(' ') rescue nil) if name.blank?
    else
      write_attribute :email, nil
    end
  end

  # true if +self+ and +other_user+ have at least one customer in common.
  def same_customer_as?(other_user)
    !(self.customers & other_user.customers).empty?
  end
  
  # Returns the CustomerUser object which forms the link between this user and a given customer
  def link_to(customer)
    customer_users.first(:conditions => {:customer_id => customer.id})
  end
  
  # true iff +self+ has an admin role connecting them to +customer+.
  def is_admin_for?(customer)
    role = link_to(customer)
    !role.nil? && (role.role == 'admin')
  end

  # true if +other_user+ is +self+ or if +self+ has administrative powers over +other_user+.
  def can_edit_user?(other_user, current_customer)
    (other_user == self) || is_admin_for?(current_customer)
  end

  # Avoid suspended/deleted users from getting entry by resetting their password
  def can_reset_password?
    passive? || pending? || active?
  end

  def password_reset_email!
    UserMailer.deliver_password_reset self
  end

  protected

  def activate_when_password_set
    if passive? && password != nil
      register!
    end
  end

end
