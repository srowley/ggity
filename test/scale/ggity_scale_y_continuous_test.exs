defmodule GGityScaleYContinuousTest do
  use ExUnit.Case

  alias GGity.Scale.Y

  describe "new/3" do
    test "creates a correct transformation function" do
      min_max = {1, 5}
      scale = Y.Continuous.new() |> Y.Continuous.train(min_max)
      assert scale.transform.(1) == 0
      assert scale.transform.(3) == 100
      assert scale.transform.(5) == 200
    end

    test "creates correct inverse and transform with one value" do
      value = {1, 1}
      scale = Y.Continuous.new() |> Y.Continuous.train(value)
      assert scale.transform.(1) == scale.width / 2
      assert scale.inverse.(1) == scale.width / 2
    end
  end
end
