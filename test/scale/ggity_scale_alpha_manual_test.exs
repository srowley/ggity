defmodule GGityScaleAlphaManualTest do
  use ExUnit.Case, async: true

  alias GGity.Scale.Alpha

  describe "new/1" do
    test "set transform function to single value" do
      assert Alpha.Manual.new(0.5).transform.("meat") == 0.5
    end

    test "raises with an invalid value" do
      assert_raise FunctionClauseError, fn -> Alpha.Manual.new(2).transform.("meat") == 2 end

      assert_raise FunctionClauseError, fn ->
        Alpha.Manual.new("dark").transform.("meat") == "dark"
      end
    end
  end
end
