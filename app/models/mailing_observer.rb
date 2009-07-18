class MailingObserver < ActiveRecord::Observer
  observe :user, :customer_user

  def after_create(object)
    if object.kind_of?(CustomerUser) && object.state == 'pending'
      UserMailer.deliver_invitation(object.customer, object.user)

    elsif object.kind_of?(User) && object.state == 'pending'
      UserMailer.deliver_activation(object)
    end
  end
end
