# People to pester if an unhandled exception occurs.
# This really should go in config/environments/production.rb, but there's a bug in Rails 2.3.2
# which causes these values to get overwritten if we put this configuration in production.rb.
ExceptionNotifier.exception_recipients = %w(admins@example.com)
ExceptionNotifier.sender_address = %("Production Site" <errors@example.com>)
