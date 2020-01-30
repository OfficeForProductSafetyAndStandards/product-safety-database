module Users
  class CreateSession
    include Interactor::Organizer

    organize Load
  end
end
