class Token::Base < ActiveRecord::Base

  extend Authentication::ModelClassMethods # provides make_token method

  set_table_name :tokens

  validates_presence_of :code
  validates_uniqueness_of :code
  validates_presence_of :type

  serialize :param

  def valid_token?
    @in_checked_transaction = @in_transaction
    if expired? then
      errors.add_to_base "has expired."

    elsif overused? then
      errors.add_to_base "has already been used."

    else
      return true

    end
    false
  end

  def overused?
    max_uses && use_count >= max_uses || false
  end

  def expired?
    expires && Time.current > expires || false
  end

  def transaction(&block)
    @in_transaction = true
    begin
      ActiveRecord::Base.transaction &block
    ensure
      @in_transaction = @in_checked_transaction = false
    end
  end

  def use!
    if @in_checked_transaction then
      self.use_count = (self.use_count || 0) + 1
      save!
    else
      throw "You may only use a token from within a transaction that has checked it is valid."
    end
  end

  # Returns a token with a given code, or the +invalid_token+ singleton if none was found.
  def self.find_by_code(code)
    Token::Base.find(:first, :conditions => {:code => code, :type => self.to_s}) or self.invalid_token
  end

  # Singleton instance of this class, representing an invalid token. Returned by +find_by_code+
  # if no matching token can be found; useful because it simplifies controller logic.
  # Each subclass of Token::Base has its own invalid_token object.
  def self.invalid_token
    @@invalid_tokens ||= {}
    return @@invalid_tokens[self] if @@invalid_tokens[self]

    token = self.new
    def token.valid_token?
      errors.add_to_base "Sorry, we could not recognise this invitation code."
      false
    end

    def token.use!
      throw "Tried to use an invalid token"
    end
    @@invalid_tokens[self] = token
  end

  # Pseudorandom alphanumeric codes that are very probably unique
  def self.new_with_code
    token = self.new
    token.code = make_token
    token
  end
end
