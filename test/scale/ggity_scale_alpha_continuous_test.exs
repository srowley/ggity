defmodule GGityScaleAlphaContinuousTest do
  use ExUnit.Case, async: true

  alias GGity.Scale.Alpha

  setup do
    %{min_max: {0, 3}}
  end

  describe "draw/2" do
    test "returns a correct scale given default options", %{min_max: min_max} do
      scale = Alpha.Continuous.train(Alpha.Continuous.new(), min_max)

      assert_in_delta scale.transform.(0), 0.1, 0.0000001
      assert_in_delta scale.transform.(1), 0.4, 0.0000001
      assert_in_delta scale.transform.(2), 0.7, 0.0000001
      assert_in_delta scale.transform.(3), 1, 0.0000001
    end

    test "returns a correct scale given custom min and max", %{min_max: min_max} do
      scale =
        [range: {0.2, 0.8}]
        |> Alpha.Continuous.new()
        |> Alpha.Continuous.train(min_max)

      assert_in_delta scale.transform.(0), 0.2, 0.0000001
      assert_in_delta scale.transform.(1), 0.4, 0.0000001
      assert_in_delta scale.transform.(2), 0.6, 0.0000001
      assert_in_delta scale.transform.(3), 0.8, 0.0000001
    end
  end
end
