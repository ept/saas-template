class Token::Base < ActiveRecord::Base

  set_table_name :tokens

  validates_presence_of :code
  validates_uniqueness_of :code
  validates_presence_of :type

  def param
    if read_attribute :param
      Marshal.load read_attribute(:param)
    else
      nil
    end
  end
  
  def param=(value)
    write_attribute :param, Marshal.dump(value)
  end

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
    max_uses and use_count >= max_uses or false
  end

  def expired?
    expires and expires < Time.current or false
  end

  def transaction (&block)
    @in_transaction = true
    ActiveRecord::Base.transaction &block
    @in_transaction = @in_checked_transaction = false
  end

  def use!
    if @in_checked_transaction then
      self.use_count = (self.use_count || 0) + 1
      save!
    else
      throw "You may only use a token from within a transaction that has checked it is valid."
    end
  end

  def self.find_by_code(code)
    Token::Base.find(:first, :conditions => {:code => code, :type => self.to_s}) or self.invalid_token
  end

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
    token.code = (Time.now.to_f.to_s.reverse + rand.to_s).gsub('.','').to_i.to_s(36)
    token
  end

end
