defmodule GGityScaleColorManualTest do
  use ExUnit.Case

  alias GGity.Scale.Color

  describe "new/1" do
    test "set transform function to single value" do
      assert Color.Manual.new("black").transform.("meat") == "black"
    end

    test "raises with an invalid value" do
      assert_raise FunctionClauseError, fn -> Color.Manual.new(4).transform.("meat") == 4 end
    end
  end
end
