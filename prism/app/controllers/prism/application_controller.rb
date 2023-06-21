module Prism
  class ApplicationController < ActionController::Base
    include Pagy::Backend

    default_form_builder GOVUKDesignSystemFormBuilder::FormBuilder
  end
end
