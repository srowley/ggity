defmodule GGity.Stat do
  @moduledoc false

  @type dataset :: list(map())

  @doc false
  @spec identity(dataset(), map()) :: {dataset(), map()}
  def identity(data, mapping), do: {data, mapping}

  # TODO: generalize this function so that it know which aesthetics to interact
  # based on the provided mapping and whether or not the associated scale is discrete
  @doc false
  @spec count(dataset(), map()) :: {dataset(), map()}
  def count(data, mapping) do
    permutations =
      for row <- data,
          uniq: true,
          do: {row[mapping[:x]], row[mapping[:fill]], row[mapping[:alpha]], row[mapping[:group]]}

    stat =
      Enum.reduce(permutations, [], fn {x_value, fill_value, alpha_value, group_value}, stat ->
        [
          Map.new([
            {mapping[:x], x_value},
            {mapping[:fill], fill_value},
            {mapping[:alpha], alpha_value},
            {mapping[:group], group_value},
            {:count,
             Enum.count(data, fn row ->
               {row[mapping[:x]], row[mapping[:fill]], row[mapping[:alpha]], row[mapping[:group]]} ==
                 {x_value, fill_value, alpha_value, group_value}
             end)}
          ])
          | stat
        ]
      end)
      |> Enum.sort_by(fn row -> row[mapping[:x]] end)

    mapping = Map.put(mapping, :y, :count)
    {stat, mapping}
  end
end
