defmodule GGityScaleIdentityTest do
  use ExUnit.Case

  alias GGity.Scale

  describe "train/2" do
    test "returns a proper scale for discrete values" do
      scale =
        :color
        |> Scale.Identity.new()
        |> Scale.train(["meat", "potatoes"])

      assert scale.transform.("meat") == "meat"
      assert scale.transform.("potatoes") == "potatoes"
    end
  end
end
