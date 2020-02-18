class SignUserIn
  include Interactor::Organizer

  organize FormValidator, Authentication
end
