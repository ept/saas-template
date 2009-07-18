domain_name = Rails::configuration.domain_name
puts "Domain name for this environment is #{domain_name}"

# Allow sessions to persist across subdomains
ActionController::Base.session_options[:domain] = domain_name
SubdomainFu.tld_size = domain_name.split('.').size - 1

# Why doesn't rails do this itself...
ActionMailer::Base.default_url_options[:host] = domain_name.sub /:.*$/,''
ActionMailer::Base.default_url_options[:port] = domain_name.sub /^.*:/,'' if domain_name.index(":")
