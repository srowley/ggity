defmodule GGityScaleSizeTest do
  use ExUnit.Case

  alias GGity.Scale.Size

  setup do
    %{min_max: {0, 3}}
  end

  describe "new/2" do
    test "returns a correct scale given default options", %{min_max: min_max} do
      scale =
        Size.new()
        |> Size.train(min_max)

      assert_in_delta scale.transform.(0), 0, 0.0000001
      assert_in_delta scale.transform.(1), 11.666666, 0.000001
      assert_in_delta scale.transform.(2), 23.333333, 0.000001
      assert_in_delta scale.transform.(3), 35, 0.0000001
    end

    test "returns a correct scale given custom range", %{min_max: min_max} do
      scale =
        Size.new(range: {2, 5})
        |> Size.train(min_max)

      assert_in_delta scale.transform.(0), 0, 0.0000001
      assert_in_delta scale.transform.(1), 7, 0.0000001
      assert_in_delta scale.transform.(2), 14, 0.0000001
      assert_in_delta scale.transform.(3), 21, 0.0000001
    end
  end
end
