defmodule GGityScaleXDateTimeTest do
  use ExUnit.Case

  alias GGity.Scale.X

  describe "train/2" do
    test "creates a correct transformation function for NaiveDateTime values" do
      values = [
        ~N[2001-01-01 00:00:00],
        ~N[2001-01-03 00:00:00],
        ~N[2001-01-05 00:00:00]
      ]

      [date1, date2, date3] = values
      scale = X.DateTime.new() |> X.DateTime.train({date1, date3})
      assert scale.transform.(date1) == 0
      assert scale.transform.(date2) == 100
      assert scale.transform.(date3) == 200
    end

    test "creates a correct transformation function for DateTime values" do
      values = [
        ~U[2001-01-01 00:00:00Z],
        ~U[2001-01-03 00:00:00Z],
        ~U[2001-01-05 00:00:00Z]
      ]

      [date1, date2, date3] = values
      scale = X.DateTime.new() |> X.DateTime.train({date1, date3})
      assert scale.transform.(date1) == 0
      assert scale.transform.(date2) == 100
      assert scale.transform.(date3) == 200
    end

    test "raises with non-date time values" do
      min_max = {1, 4}
      assert_raise FunctionClauseError, fn -> X.DateTime.new() |> X.DateTime.train(min_max) end
    end
  end
end
