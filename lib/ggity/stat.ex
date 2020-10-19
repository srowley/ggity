defmodule GGity.Stat do
  @moduledoc false

  @type dataset :: list(map())

  @doc false
  @spec identity(dataset(), map()) :: {dataset(), map()}
  def identity(data, mapping), do: {data, mapping}

  @spec count(dataset(), map()) :: {dataset(), map()}
  def count(data, mapping) do
    discrete_aesthetics = discrete_aesthetics(data, mapping)

    permutations =
      for row <- data,
          uniq: true,
          do:
            discrete_aesthetics
            |> Enum.map(fn aesthetic -> {aesthetic, row[mapping[aesthetic]]} end)
            |> Map.new()

    stat =
      Enum.reduce(permutations, [], fn permutation, stat ->
        [
          Map.new(
            Enum.map(discrete_aesthetics, fn aesthetic ->
              {mapping[aesthetic], permutation[aesthetic]}
            end)
          )
          |> Map.put(
            :count,
            Enum.count(data, fn row ->
              Enum.map(permutation, fn {k, _v} -> row[mapping[k]] end) ==
                Enum.map(permutation, fn {_k, v} -> v end)
            end)
          )
          | stat
        ]
      end)
      |> Enum.sort_by(fn row -> row[mapping[:x]] end)

    mapping = Map.put(mapping, :y, :count)
    {stat, mapping}
  end

  defp discrete_aesthetics(data, mapping) do
    discrete_variables =
      data
      |> hd()
      |> Enum.filter(fn {_k, v} -> is_binary(v) end)
      |> Enum.map(fn {k, _v} -> k end)

    mapping
    |> Enum.filter(fn {_k, v} -> v in discrete_variables end)
    |> Keyword.keys()
  end
end
