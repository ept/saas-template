# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
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
end
