defmodule GGityGeomPointTest do
  use ExUnit.Case

  alias GGity.Geom

  describe "new/3" do
    test "adds mapping and fixed aesthetics specified as options" do
      geom = Geom.Point.new(%{x: :wt, y: :mpg}, alpha: 0.5, color: "red")
      assert geom.mapping == %{x: :wt, y: :mpg}
      assert geom.color == "red"
      assert geom.alpha == 0.5
    end
  end
end
