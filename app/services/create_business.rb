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
    end
  end
end
