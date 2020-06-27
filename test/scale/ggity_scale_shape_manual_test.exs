defmodule GGityScaleShapeManual do
  use ExUnit.Case

  alias GGity.Scale.Shape

  describe "new/1" do
    test "set transform function to single value given valid shape name" do
      assert Shape.Manual.new(:circle).transform.("meat") == :circle
    end

    test "set transform function to single value given a binary" do
      assert Shape.Manual.new("A").transform.("meat") == "A"
    end

    test "set transform function to a custom list" do
      assert Shape.Manual.new([1, 2, 3], values: ["a", "b", "c"]).transform.(2) == "b"
    end

    test "raises with an invalid value" do
      assert_raise FunctionClauseError, fn -> Shape.Manual.new(2).transform.("meat") == 2 end

      assert_raise FunctionClauseError, fn ->
        Shape.Manual.new(:rhombus).transform.("meat") == :rhombus
      end
    end
  end
end
