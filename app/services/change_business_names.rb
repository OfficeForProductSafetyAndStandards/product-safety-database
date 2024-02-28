class ChangeBusinessNames
  include Interactor

  delegate :trading_name, :legal_name, :company_number, :business, :user, to: :context

  def call
    context.fail!(error: "No trading name supplied") unless trading_name.is_a?(String)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    business.assign_attributes(legal_name:, trading_name:, company_number:, added_by_user_id: user.id)

    business.save!
  end
end
