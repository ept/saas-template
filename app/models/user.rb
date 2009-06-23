require 'digest/sha1'

class User < ActiveRecord::Base

  class UserSuspended < StandardError; end

  has_many :customers, :through => :customer_users
  has_many :customer_users

  include Authentication
  include Authentication::ByPassword
  include Authentication::ByCookieToken
  include Authorization::AasmRoles

  validates_format_of       :name,     :with => Authentication.name_regex,  :message => Authentication.bad_name_message, :allow_nil => true
  validates_length_of       :name,     :maximum => 100

  validates_presence_of     :email
  validates_length_of       :email,    :within => 6..100 #r@a.wk
  validates_uniqueness_of   :email
  validates_format_of       :email,    :with => Authentication.email_regex, :message => Authentication.bad_email_message

  

  # HACK HACK HACK -- how to do attr_accessible from here?
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :email, :name, :password, :password_confirmation



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
    user = User.new(:email => email, :password => password, :name => email[/^[^@]+/], :password_confirmation => password)
    user.is_admin = 0
    user.state = :active
    user.save!
    user
  end

  def email=(value)
    write_attribute :email, (value ? value.downcase : nil)
  end

  # true if +self+ and +other_user+ have at least one customer in common.
  def same_customer_as?(other_user)
    !(self.customers & other_user.customers).empty?
  end

  protected
    
  def make_activation_code
    self.deleted_at = nil
    self.activation_code = self.class.make_token
  end


end
