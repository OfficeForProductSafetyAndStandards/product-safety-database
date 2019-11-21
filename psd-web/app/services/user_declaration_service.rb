class UserDeclarationService
  def self.accept_declaration(user)
    attributes_to_update = { has_accepted_declaration: true, account_activated: true }

    unless user.has_been_sent_welcome_email
      NotifyMailer.welcome(user.name, user.email).deliver_later
      attributes_to_update[:has_been_sent_welcome_email] = true
    end

    user.update!(attributes_to_update)

    return true
  end
end
