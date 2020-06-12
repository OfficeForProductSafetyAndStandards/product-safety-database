class TestDecorator < ApplicationDecorator
  delegate_all
  include SupportingInformationHelper
end
