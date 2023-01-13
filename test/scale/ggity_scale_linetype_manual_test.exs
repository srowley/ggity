defmodule GGityScaleLinetypeManual do
  use ExUnit.Case, async: true

  alias GGity.Scale.Linetype

  describe "new/1" do
    test "set transform function to single value" do
      assert Linetype.Manual.new(:solid).transform.("meat") == ""
    end

    test "raises with an invalid value" do
      assert_raise FunctionClauseError, fn -> Linetype.Manual.new(2).transform.("meat") == 2 end

      assert_raise FunctionClauseError, fn ->
        Linetype.Manual.new("dark").transform.("meat") == "dark"
      end

      assert_raise FunctionClauseError, fn ->
        Linetype.Manual.new(:squiggly).transform.("meat") == :squiggly
      end
    end
  end
end
