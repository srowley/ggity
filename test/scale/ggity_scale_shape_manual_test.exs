defmodule GGityScaleShapeManual do
  use ExUnit.Case, async: true

  alias GGity.Scale.Shape

  describe "train/2" do
    test "set transform function to single value given a binary" do
      scale = Shape.Manual.new(values: ["A"])
      assert Shape.Manual.train(scale, ["meat"]).transform.("meat") == "A"
    end

    test "set transform function to a custom list" do
      scale = Shape.Manual.new(values: ["a", "b", "c"])
      assert Shape.Manual.train(scale, ["1", "2", "3"]).transform.(2) == "b"
    end

    test "raises with an invalid value" do
      assert_raise FunctionClauseError, fn -> Shape.Manual.new(values: [2]) end
      assert_raise FunctionClauseError, fn -> Shape.Manual.new(values: [:rhombus]) end
    end
  end
end
