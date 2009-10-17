class CustomerAddress < ActiveRecord::Base
  belongs_to :customer

  attr_accessor :is_self

  def initialize(*args)
    super
    self.is_self = false
  end

  def self.this_site
    address = new :name => "Ept Computing Ltd",
      :contact_name => "Martin Kleppmann",
      :address => "St John's Innovation Centre\nCowley Road",
      :city => "Cambridge",
      :state => "",
      :postal_code => "CB4 0WS",
      :country => "United Kingdom",
      :country_code => "GB",
      :tax_number => "GB 913 1069 56"
    address.is_self = true
    address
  end

  def self.for_customer(customer)
    return this_site if customer.nil?
    customer.customer_addresses.first || create(:customer_id => customer.id, :name => customer.name)
  end

  def details_hash
    attributes.symbolize_keys.merge({:is_self => is_self})
  end
end
