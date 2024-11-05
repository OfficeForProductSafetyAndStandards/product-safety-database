RSpec.shared_context "with stubbed notify" do
  let!(:notifications_response) do
    Class.new do
      attr_reader :id, :content, :template

      def initialize(id:, content:, template:)
        @id = id
        @content = content
        @template = template
      end
    end
  end

  let!(:notify_stub) do
    instance_double(Notifications::Client).tap do |double|
      allow(double).to receive(:send_sms) do |args|
        notifications_response.new(
          id: "740e5834-3a29-46b4-9a6f-16142fde533a",
          content: {
            body: "Your code is #{args[:personalisation][:code]}",
            from_number: "40604"
          },
          template: {
            id: args[:template_id],
            version: 1,
            uri: "/v2/templates/#{args[:template_id]}"
          }
        )
      end
    end
  end

  before do
    # Clear any previous stubs
    RSpec::Mocks.space.proxy_for(Notifications::Client).reset

    # Stub the constructor more explicitly
    client_class = class_double(Notifications::Client).as_stubbed_const
    allow(client_class).to receive(:new).with(any_args).and_return(notify_stub)

    # Stub Phonelib validation to return whatever number was passed in
    allow(Phonelib).to receive(:parse) do |number|
      instance_double(
        Phonelib::Phone,
        valid?: true,
        country_code: "44",
        international: number # Return the number that was passed in
      )
    end
  end
end

RSpec.configure do |rspec|
  rspec.include_context "with stubbed notify", :with_stubbed_notify
end
