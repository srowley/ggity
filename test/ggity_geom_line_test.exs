defmodule GGityGeomLineTest do
  use ExUnit.Case

  alias GGity.Geom

  describe "new/3" do
    test "adds fixed aesthetics specified as options" do
      geom = Geom.Line.new(%{x: :wt, y: :mpg}, linetype: :dashed, color: "red")
      assert geom.mapping == %{x: :wt, y: :mpg}
      assert geom.color == "red"
      assert geom.linetype == "4"
    end

    test "sets default linetype" do
      geom = Geom.Line.new(%{x: :wt, y: :mpg})
      assert geom.linetype == ""
    end
  end
end
