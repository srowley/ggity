defmodule GGityScaleSizeManualTest do
  use ExUnit.Case, async: true

  alias GGity.Scale.Size

  describe "new/1" do
    test "set transform function to single value" do
      assert Size.Manual.new(4).transform.("meat") == 4
    end

    test "raises with an invalid value" do
      assert_raise FunctionClauseError, fn -> Size.Manual.new("big").transform.("meat") == 4 end
    end
  end
end
