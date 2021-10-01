class CreateBusiness
  include Interactor
  include EntitiesToNotify

  delegate :user, :trading_name, :legal_name, :company_number, :skip_email, to: :context

  def call
    context.fail!(error: "No user supplied")          unless user.is_a?(User)

    Business.transaction do
      business = Business.create!(trading_name: trading_name, legal_name: legal_name, company_number: company_number)
      business.primary_location&.assign_attributes(name: "Registered office address", source: UserSource.new(user: user))
      business.save!

      # send_notification_email(
      #   create_audit_activity_for_business_added(business)
      # )
    end
  end

private

  # def create_audit_activity_for_business_added(business)
  #   AuditActivity::Business::Add.create!(
  #     investigation: investigation,
  #     source: UserSource.new(user: user),
  #     business: business,
  #     metadata: AuditActivity::Business::Add.build_metadata(business)
  #   )
  # end

  # def send_notification_email(activity)
  #   return if skip_email
  #
  #   email_recipients_for_case_owner.each do |recipient|
  #     NotifyMailer.investigation_updated(
  #       investigation.pretty_id,
  #       recipient.name,
  #       recipient.email,
  #       "Business was added to the #{investigation.case_type} by #{activity.source.show(recipient)}.",
  #       "Business added"
  #     ).deliver_later
  #   end
  # end
end
