require "rails/test_unit/runner"

namespace :test do
  desc "Run minitest tests without System tests"
  task without_system_tests: "test:prepare" do
    $LOAD_PATH << "test"
    test_files = FileList["test/**/*_test.rb"].exclude("test/system/**/*_test.rb")
    Rails::TestUnit::Runner.run(test_files)
  end

  desc "Run a slice of minitest System tests files"
  task system_slice: "test:prepare" do
    # Issue does not apply when the method is declared inside task block.
    # rubocop:disable Rake/MethodDefinitionInTask
    def system_tests_files_slice(slice:, total_slices:)
      return [] unless slice.positive? && slice <= total_slices

      FileList["test/system/**/*_test.rb"]
        .to_a
        .in_groups(total_slices, false)
        .at(slice - 1)
    end
    # rubocop:enable Rake/MethodDefinitionInTask
    $: << "test"
    slice = ENV.fetch("TEST_SLICE", 1).to_i
    total_slices = ENV.fetch("TEST_TOTAL_SLICES", 1).to_i

    test_files = system_tests_files_slice(slice: slice, total_slices: total_slices)
    puts "Running system tests: #{test_files}"

    Rails::TestUnit::Runner.run(test_files)
  end
end
