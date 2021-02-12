require "test_helper"

class GeneralTest < ActiveSupport::TestCase

  setup do
  end

  teardown do
  end
  
  def test_load_ruby_code_for_syntax_errors
    load("../migration.rb")
  end

end
