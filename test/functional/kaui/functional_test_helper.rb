class Kaui::FunctionalTestHelper < Kaui::FunctionalTestHelperNoSetup

  # Called before every single test
  setup do

    Kaui::ApplicationRecord.subclasses.each(&:delete_all)
    setup_functional_test

  end

  # Called after every single test
  teardown do
    teardown_functional_test
  end
end
