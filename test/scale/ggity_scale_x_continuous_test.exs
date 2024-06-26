defmodule GGityScaleXContinuousTest do
  use ExUnit.Case, async: true

  alias GGity.Scale.X

  describe "new/3" do
    test "creates a correct transformation function" do
      min_max = {1, 5}
      scale = X.Continuous.train(X.Continuous.new(), min_max)
      assert scale.transform.(1) == 0
      assert scale.transform.(3) == 100
      assert scale.transform.(5) == 200
    end
  end
end
