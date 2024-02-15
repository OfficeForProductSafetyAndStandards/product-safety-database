class ChangeBusinessNames
  include Interactor

  delegate :trading_name, :legal_name, :notification, :business, :user, to: :context

  def call
    context.fail!(error: "No trading name supplied") unless trading_name.is_a?(String)

    business.assign_attributes(legal_name:, trading_name:)

    business.save!
  end
end
