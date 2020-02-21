defmodule GGityScaleSizeContinuousTest do
  use ExUnit.Case

  alias GGity.Scale.Size

  setup do
    %{values: [0, 1, 2, 3, 4]}
  end

  describe "new/2" do
    test "returns a correct scale given default options", %{values: values} do
      scale = Size.Continuous.new(values)
      assert_in_delta scale.transform.(0), 4, 0.0000001
      assert_in_delta scale.transform.(1), 6.5, 0.0000001
      assert_in_delta scale.transform.(2), 9, 0.0000001
      assert_in_delta scale.transform.(3), 11.5, 0.0000001
      assert_in_delta scale.transform.(4), 14, 0.0000001
    end

    test "returns a correct scale given custom min and max", %{values: values} do
      scale = Size.Continuous.new(values, size_min: 2, size_max: 6)
      assert_in_delta scale.transform.(0), 2, 0.0000001
      assert_in_delta scale.transform.(1), 3, 0.0000001
      assert_in_delta scale.transform.(2), 4, 0.0000001
      assert_in_delta scale.transform.(3), 5, 0.0000001
      assert_in_delta scale.transform.(4), 6, 0.0000001
    end
  end
end
