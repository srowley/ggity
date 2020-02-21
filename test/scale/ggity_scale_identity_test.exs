defmodule GGityScaleIdentityTest do
  use ExUnit.Case

  alias GGity.Scale

  setup do
    %{
      plot:
        GGity.Plot.new([%{x: 1, y: 1, z: "meat"}, %{x: 2, y: 2, z: "potatoes"}], %{
          x: :x,
          y: :y,
          color: :z
        })
    }
  end

  describe "new/2" do
    test "returns a proper scale for discrete values", %{plot: plot} do
      scale = Scale.Identity.new(plot, :color)
      assert scale.transform.("meat") == "meat"
      assert scale.transform.("potatoes") == "potatoes"
    end

    test "raises when aesthetic is not valid", %{plot: plot} do
      assert_raise FunctionClauseError, fn -> Scale.Identity.new(plot, :meat) end
    end
  end
end
