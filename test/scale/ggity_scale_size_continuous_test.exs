defmodule GGityScaleSizeContinuousTest do
  use ExUnit.Case

  alias GGity.Scale.Size

  setup do
    %{min_max: {0, 4}}
  end

  describe "new/2" do
    test "returns a correct scale given default options", %{min_max: min_max} do
      scale =
        Size.Continuous.new()
        |> Size.Continuous.train(min_max)

      assert_in_delta scale.transform.(0), 3, 0.0000001
      assert_in_delta scale.transform.(1), 5.634714, 0.000001
      assert_in_delta scale.transform.(2), 7.382412, 0.00001
      assert_in_delta scale.transform.(3), 8.789198, 0.000001
      assert_in_delta scale.transform.(4), 10, 0.0000001
    end

    test "returns a correct scale given custom min and max", %{min_max: min_max} do
      scale =
        Size.Continuous.new(size_min: 4, size_max: 121)
        |> Size.Continuous.train(min_max)

      assert_in_delta scale.transform.(0), 2, 0.0000001
      assert_in_delta scale.transform.(1), 5.766281, 0.000001
      assert_in_delta scale.transform.(2), 7.905694, 0.000001
      assert_in_delta scale.transform.(3), 9.578622, 0.0000001
      assert_in_delta scale.transform.(4), 11, 0.0000001
    end
  end
end
