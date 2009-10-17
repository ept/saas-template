# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include SecureDomain

  # Returns the full URL for a token, for use in emails.
  def token_url(token, options={})
    options = secure_subdomain.merge(options.symbolize_keys)
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


  # Label for a checkbox or radio button, because ActionView's label helper is crap
  # cf. ActionView::Helpers::FormTagHelper#radio_button_tag
  def value_label(name, value, text)
    pretty_tag_value = value.to_s.gsub(/\s/, "_").gsub(/(?!-)\W/, "").downcase
    pretty_name = name.to_s.gsub(/\[/, "_").gsub(/\]/, "")
    "<label for=\"#{pretty_name}_#{pretty_tag_value}\">#{h(text)}</label>"
  end

  # Generate Javascript to hide and show parts of a page based on the value of checkboxes
  # or radio buttons.
  def reveal( what, options )
    prefix = options[:prefix]

    @hide_and_show_data << if options[:is_one_of]
      # radio button
      name = "#{prefix}[#{options[:only_if]}]"

      "  var radioGroup = $(':radio').filter(function(){ return $(this).attr('name') == '#{name}'; });\n" +
      "  radioGroup.change(function(){\n" +
      "    var checked = radioGroup.filter(':checked');\n" +
      "    var value = (checked.length == 0) ? '' : checked.attr('value');\n" +
      "    switch(value) {\n" +
      options[:is_one_of].map{|val| "      case '#{val}':\n"}.join +
      "        $('##{what}').show();\n" +
      "        break;\n" +
      "      default:\n" +
      "        $('##{what}').hide();\n" +
      "    }\n" +
      "  }).change();\n"

    else
      # check box
      negation = (options[:is].to_sym == :checked || options[:is] == true) ? '' : '!'

      "  $('##{prefix}_#{options[:only_if]}').change(function(){\n" +
      "    if(#{negation}$(this).attr('checked')) {\n" +
      "      $('##{what}').slideDown(animSpeed);\n" +
      "    } else {\n" +
      "      $('##{what}').slideUp(animSpeed);\n" +
      "    }\n" +
      "  }).change();\n"
    end
  end

  # Wrapper for reveal helper
  def hide_and_show
    @hide_and_show_data = ''
    yield
    "<script type=\"text/javascript\">\n" +
    "$(function() {\n" +
    @hide_and_show_data +
    "});\n</script>\n"
  end
end
