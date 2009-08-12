module Token
  class TrackingKeyword < Base
    def handle_redirect
      target = {:controller => 'about', :action => 'index'}
      if param
        target[:utm_source] = 'url_keyword'
        target[:utm_medium] = param[:medium] if param[:medium]
        target[:utm_campaign] = param[:campaign] if param[:campaign]
      end
      target
    end

    def store_in_session?
      true
    end
  end
end
