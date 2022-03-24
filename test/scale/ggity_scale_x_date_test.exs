defmodule GGityScaleXDateTest do
  use ExUnit.Case

  alias GGity.Scale.X

  describe "new/3" do
    test "creates a correct transformation function" do
      min_max = {~D[2001-01-01], ~D[2001-12-31]}
      scale = X.Date.train(X.Date.new(), min_max)
      assert scale.transform.(~D[2001-01-01]) == 1 / 365 * 200
      assert scale.transform.(~D[2001-07-02]) < 100 + 1 / 365 * 200
      assert scale.transform.(~D[2001-07-03]) > 100

      assert_in_delta scale.transform.(~D[2001-07-03]) - scale.transform.(~D[2001-07-02]),
                      1 / 365 * 200,
                      0.000001

      assert scale.transform.(~D[2002-01-01]) == 200 + 1 / 365 * 200
    end
  end
end
