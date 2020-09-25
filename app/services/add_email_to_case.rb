class AddEmailToCase
  include Interactor

  delegate :investigation, :user, :correspondent_name, :email_address, :email_direction, :overview, :details, :email_subject, :email_file, :email_attachment, to: :context

  def call
    context.email = @investigation.emails.new(
      correspondent_name: correspondent_name,
      email_address: email_address,
      email_direction: email_direction,
      overview: overview,
      details: details,
      email_subject: email_subject
    )

    # TODO: refactor into model
    @correspondence.set_dates_from_params(params[:correspondence_email])

    # TODO: refactor into a service class
    if !@correspondence.email_attachment.attached? && params[:existing_email_attachment]
      @correspondence.email_attachment.attach(params[:existing_email_attachment])
    end
  end
end
