class ResendSecondaryAuthenticationCodeForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :mobile_number
  attribute :user

  validates_presence_of :mobile_number,
                        message: I18n.t(:blank, scope: %i[activerecord errors models user attributes mobile_number]),
                        if: -> { update_mobile_number? }
  validates :mobile_number,
            phone: { message: I18n.t(:invalid, scope: %i[activerecord errors models user attributes mobile_number]) },
            if: -> { update_mobile_number? && mobile_number.present? }

private

  def update_mobile_number?
    !user.mobile_number_verified
  end
end
