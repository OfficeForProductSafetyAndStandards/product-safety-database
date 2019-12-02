class Investigation < ApplicationRecord
  class Create
    def initialize(attributes, user: nil)
      self.attributes = attributes
      self.user       = user
    end

    def call
      if investigation.save
        send_confirmation_email
        investigation.create_audit_activity_for_case
      end

      investigation
    end

  private

    attr_accessor :attributes, :user

    def investigation
      @investigation ||= Investigation.new(attributes)
    end

    def send_confirmation_email
      return unless user

      decorated = investigation.decorate

      NotifyMailer.investigation_created(
        decorated.pretty_id,
        user.name,
        user.email,
        decorated.title,
        decorated.case_type
      ).deliver_later
    end
  end
end
