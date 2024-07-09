RSpec::Matchers.define :not_talk_to_db do |_expected|
  match do |block_to_test|
    stub_methods = %w[exec_delete exec_insert exec_query exec_update]

    connection_double = instance_double(ActiveRecord::ConnectionAdapters::AbstractAdapter, Hash[stub_methods.zip])
    allow(ActiveRecord::Base).to receive(:connection).and_return(connection_double)

    block_to_test.call

    stub_methods.each { |meth| expect(connection_double).not_to have_received(meth) }
  end
  supports_block_expectations
end
