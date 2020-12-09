module ErrorsHelper
  def file_validation_errors?(errors, attribute:)
    errors.details[attribute].any? { |error| (error.value? :file_too_large) || (error.value? :file_missing) || (error.value? :blank) }
  end
end
