defmodule GGityScaleShapeManual do
  use ExUnit.Case

  alias GGity.Scale.Shape

  describe "new/1" do
    test "set transform function to single value" do
      assert Shape.Manual.new(:circle).transform.("meat") == :circle
    end

    test "raises with an invalid value" do
      assert_raise FunctionClauseError, fn -> Shape.Manual.new(2).transform.("meat") == 2 end

      assert_raise FunctionClauseError, fn ->
        Shape.Manual.new("dark").transform.("meat") == "dark"
      end

      assert_raise FunctionClauseError, fn ->
        Shape.Manual.new(:rhombus).transform.("meat") == :rhombus
      end
    end
  end
end
