defmodule GGityScaleXDateTest do
  use ExUnit.Case

  alias GGity.Scale.X

  describe "new/3" do
    test "creates a correct transformation function" do
      min_max = {~D[2001-01-01], ~D[2001-12-31]}
      scale = X.Date.new() |> X.Date.train(min_max)
      assert scale.transform.(~D[2001-01-01]) == 0
      assert scale.transform.(~D[2001-07-02]) < 100
      assert scale.transform.(~D[2001-07-03]) > 100

      assert_in_delta scale.transform.(~D[2001-07-03]) - 100 -
                        (100 - scale.transform.(~D[2001-07-02])),
                      0,
                      0.000001

      assert scale.transform.(~D[2002-01-01]) == 200
    end
  end
end
