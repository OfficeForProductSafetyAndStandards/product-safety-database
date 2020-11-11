class CreateRiskAssessment
  include Interactor::Organizer

  organize CacheUploadedFile, ValidateForm, SerialiseFormAttributes, AddRiskAssessmentToCase
end
