module Users
  class CreateSession
    include Interactor::Organizer

    organize Load # , ExchangeToken
  end
end
