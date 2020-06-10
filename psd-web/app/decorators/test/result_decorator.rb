class Test < ApplicationRecord
  require_dependency "test"
  class ResultDecorator < TestDecorator
  end
end
