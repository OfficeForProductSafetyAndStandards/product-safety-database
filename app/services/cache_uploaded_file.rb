class CacheUploadedFile
  include Interactor

  delegate :form, :files_to_cache, to: :context
  def call
    Array.wrap(files_to_cache).each do |file|
      form.cache_file!(file)
      form.load_uploaded_file(file)
    end
  end
end
