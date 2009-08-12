module Token
  class TrackingKeyword < Base
    def handle_redirect
      {:controller => 'about', :action => 'index', :utm_source => 'url_keyword',
       :utm_medium => param[:medium], :utm_campaign => param[:campaign]}
    end
  end
end
