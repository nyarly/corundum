require 'corundum/qa-report'

describe Corundum::QA::Report do
  let :report do
    Corundum::QA::Report.new("Test").tap do |test|
      test.add("thing", "a/file", 17, 100_000)
    end
  end

  it "should report as okay" do
    report.passed.should  == true
    report.to_s.should =~ /Ok/
  end

  it "should report as failed" do
    report.fail "It bwoke!"

    report.passed.should be_false
    report.to_s.should =~ /FAIL/
    report.to_s.should =~ /bwoke/
  end
end
