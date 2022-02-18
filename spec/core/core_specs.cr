require "../spec_helper"
require "../../src/cli/spec_runner"

describe "core specs" do
  it "should run the core array specs" do
    result = SpecRunner.new("./src/core/spec/array*").run(true)
    result.should eq(0)
  end

  it "should run the core object specs" do
    result = SpecRunner.new("./src/core/spec/object*").run(true)
    result.should eq(0)
  end
end
