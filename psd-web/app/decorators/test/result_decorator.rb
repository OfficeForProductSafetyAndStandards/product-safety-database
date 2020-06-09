class Test < ApplicationRecord
  class ResultDecorator < TestDecorator
    include SupportingInformationHelper
  end
end
