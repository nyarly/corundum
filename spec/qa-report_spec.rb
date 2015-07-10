require 'corundum/qa-report'

describe Corundum::QA::Report do
  let :report do
    Corundum::QA::Report.new("Test").tap do |test|
      test.add("thing", "a/file", 17, 100_000)
    end
  end

  it "should report as okay" do
    expect(report.passed).to eq(true)
    expect(report.to_s).to match(/Ok/)
  end

  it "should report as failed" do
    report.fail "It bwoke!"

    expect(report.passed).to be(false)
    expect(report.to_s).to match(/FAIL/)
    expect(report.to_s).to match(/bwoke/)
  end
end
