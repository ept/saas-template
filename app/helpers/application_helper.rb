# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  # Returns 'http' or 'https' depending on the setting in the environment
  def login_url_protocol
    Rails::configuration.https_login ? 'https' : 'http'
  end

  # When using a wildcard SSL certificate for *.example.com then requests to example.com
  # cannot be authenticated. Therefore any SSL URLs which wouldn't otherwise have a
  # subdomain should be directed to a special subdomain, e.g. secure.example.com.
  def login_url_subdomain
    Rails::configuration.https_login ? 'secure' : false
  end

  # Returns the full URL for a token, for use in emails.
  def token_url(token, options={})
    options = {
      :protocol => login_url_protocol,
      :subdomain => login_url_subdomain
    }.merge(options.symbolize_keys)
    subdomain = options.delete(:subdomain)

    url = options.delete(:protocol) + '://'
    url << subdomain + '.' if subdomain
    url << Rails::configuration.domain_name + '/' + token.code
    url << '?' + options.to_param unless options.empty?
    url
  end

  # Assuming your form is a table with haedings to the left, and errors to the right
  def form_row(f, field, label, params = {})
    type = (params[:type] || :text).to_s + '_field'
    label = field unless label
    <<-EOF
    <tr>
      <th>#{f.label field, label}</th>
      <td>#{f.send type, field}</td>
      <td>#{f.error_message_on field}</td>
    </tr>
    EOF
  end

  def for_customer_admin(&block)
    block.call if current_user && current_customer && current_user.is_admin_for?(current_customer)
  end

  # hack to make link_for work for customers
  def customer_path(customer)
    url_for :controller => :customers, :subdomain => customer.subdomain
  end
end
