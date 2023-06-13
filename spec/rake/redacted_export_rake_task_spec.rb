# rubocop:disable RSpec/DescribeClass
require "rails_helper"
Rails.application.load_tasks

describe "redacted_export:generate_sql" do
  it "generates the SQL" do
    output = run_rake_and_capture_output("redacted_export:generate_sql")
    expect(output).to include("Redacted export generation SQL complete")
  end
end

def run_rake_and_capture_output(task_name)
  stdout = StringIO.new
  $stdout = stdout
  Rake::Task[task_name].invoke
  $stdout = STDOUT
  Rake.application[task_name].reenable
  stdout.string
end

# rubocop:enable RSpec/DescribeClass
