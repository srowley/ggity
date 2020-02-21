defmodule GGityScaleAlphaContinuousTest do
  use ExUnit.Case

  alias GGity.Scale.Alpha

  setup do
    %{values: [0, 1, 2, 3]}
  end

  describe "new/2" do
    test "returns a correct scale given default options", %{values: values} do
      scale = Alpha.Continuous.new(values)
      assert_in_delta scale.transform.(0), 0.1, 0.0000001
      assert_in_delta scale.transform.(1), 0.4, 0.0000001
      assert_in_delta scale.transform.(2), 0.7, 0.0000001
      assert_in_delta scale.transform.(3), 1, 0.0000001
    end

    test "returns a correct scale given custom min and max", %{values: values} do
      scale = Alpha.Continuous.new(values, alpha_min: 0.2, alpha_max: 0.8)
      assert_in_delta scale.transform.(0), 0.2, 0.0000001
      assert_in_delta scale.transform.(1), 0.4, 0.0000001
      assert_in_delta scale.transform.(2), 0.6, 0.0000001
      assert_in_delta scale.transform.(3), 0.8, 0.0000001
    end
  end
end
