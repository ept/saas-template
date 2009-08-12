module Token
  class Base < ActiveRecord::Base

    extend Authentication::ModelClassMethods # provides make_token method

    set_table_name :tokens

    validates_presence_of :code
    validates_uniqueness_of :code
    validates_presence_of :type

    serialize :param

    # Overwrite in subclasses. +handle_redirect+ is called when a token is accessed by a user and the
    # controller needs to find out how to handle it. Should return an object from which +url_for+
    # can generate a URL.
    def handle_redirect
      nil
    end

    # Is the token valid?
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

    # Does the token exist at all?
    def exists?
      true
    end

    # Has the token been used more often than permitted?
    def overused?
      max_uses && use_count >= max_uses || false
    end

    # Has the token's expiry date passed?
    def expired?
      expires && Time.current > expires || false
    end

    # Run a block inside a database transaction.
    def transaction(&block)
      @in_transaction = true
      begin
        ActiveRecord::Base.transaction &block
      ensure
        @in_transaction = @in_checked_transaction = false
      end
    end

    # Consumes a token, marking it as used. Must be called inside a transaction, and valid_token?
    # must have been called in the same transaction.
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
      conditions = {:code => code}
      conditions[:type] = self.to_s unless self == Base
      find(:first, :conditions => conditions) || invalid_token
    end

    # Singleton instance of this class, representing an invalid token. Returned by +find_by_code+
    # if no matching token can be found; useful because it simplifies controller logic.
    # Each subclass of Token::Base has its own invalid_token object.
    def self.invalid_token
      @@invalid_tokens ||= {}
      return @@invalid_tokens[self] if @@invalid_tokens[self]

      token = self.new
      def token.valid_token?
        errors.add_to_base "Sorry, we could not recognise this code."
        false
      end

      def token.exists?
        false
      end

      def token.use!
        raise "Tried to use an invalid token"
      end
      @@invalid_tokens[self] = token
    end

    # Pseudorandom alphanumeric codes that are very probably unique
    def self.new_with_code
      token = self.new
      token.code = make_token
      token
    end

    # Override in subclasses if the token code should be remembered in the user's session.
    def store_in_session?
      false
    end
  end
end
