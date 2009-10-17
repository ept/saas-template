module Token
  class BetaInvitation < TrackingKeyword
    def self.generate_for(email, max_uses=1)
      token = new_with_code
      token.code = token.code[0..5]
      token.param ||= {}
      token.param[:email] = email
      token.param[:campaign] = 'beta'
      token.param[:medium] = 'invitation'
      token.max_uses = max_uses
      token.use_count = 0
      token.save!
      token
    end
  end
end
