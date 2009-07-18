# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

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
