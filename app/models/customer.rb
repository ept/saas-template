class Customer < ActiveRecord::Base
  attr_accessor :first_user

  # Disallow some subdomains (our actual domain names must appear here too)
  def self.reserved_subdomains
    %w( www wwww test dev staging ns1 ns2 localhost mail imap pop3 )
  end

  has_many :users, :through => :customer_users
  has_many :projects

  # RFC 1035 excluding domains shorter than three characters
  validates_presence_of :subdomain
  validates_format_of :subdomain, :with => /^[a-z][a-z0-9-]{1,61}[a-z0-9]$/
  validates_exclusion_of :subdomain, :in => Customer.reserved_subdomains
  validates_uniqueness_of :subdomain, :message => 'Sorry, this subdomain has already been taken.'

  validates_length_of :name, :in => 3..250

  def subdomain=(val)
    write_attribute :subdomain, val.downcase
    if not name then 
      write_attribute :name, val.capitalize
    end
  end

end
