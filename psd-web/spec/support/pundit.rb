RSpec.shared_context "with stubbed pundit", shared_context: :metadata do
  before do
    # Sadly we have to use allow_any_instance_of as pundit embed itself deep into ActionController
    allow_any_instance_of(ApplicationController) # rubocop:disable Rspec/AnyInstance
      .to receive(:pundit_user).and_return(current_user)
  end
end

RSpec.configure do |rspec|
  rspec.include_context "with stubbed pundit", with_stubbed_pundit: true
end
