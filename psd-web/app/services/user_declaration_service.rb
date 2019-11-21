class UserDeclarationService
  def self.accept_declaration(user)
    user.has_accepted_declaration!
    user.activate!

    unless user.has_been_sent_welcome_email
      NotifyMailer.welcome(user.name, user.email).deliver_later
      user.has_been_sent_welcome_email!
    end

    return true
  end
end
