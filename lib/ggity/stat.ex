defmodule GGity.Stat do
  @moduledoc false

  @type dataset :: list(map())

  @doc false
  @spec identity(dataset(), map()) :: {dataset(), map()}
  def identity(data, mapping), do: {data, mapping}

  @spec count(dataset(), map()) :: {dataset(), map()}
  def count(data, mapping) do
    discrete_aesthetics = discrete_aesthetics(data, mapping)
    permutations = permutations(discrete_aesthetics, data, mapping)

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

  @spec boxplot(dataset(), map()) :: {dataset(), map()}
  def boxplot(data, mapping) do
    discrete_aesthetics = discrete_aesthetics(data, mapping)
    permutations = permutations(discrete_aesthetics, data, mapping)

    stat =
      Enum.reduce(permutations, [], fn permutation, stat ->
        [
          Map.new(
            Enum.map(discrete_aesthetics, fn aesthetic ->
              {mapping[aesthetic], permutation[aesthetic]}
            end)
          )
          |> Map.merge(boxplot_stats_map(data, mapping, permutation))
          | stat
        ]
      end)
      |> Enum.sort_by(fn row -> row[mapping[:x]] end)

    {stat, mapping}
  end

  defp boxplot_stats_map(data, mapping, permutation) do
    permutation_data =
      data
      |> Enum.filter(fn row ->
        Enum.map(permutation, fn {k, _v} -> row[mapping[k]] end) ==
          Enum.map(permutation, fn {_k, v} -> v end)
      end)
      |> Enum.map(fn row -> row[mapping[:y]] end)
      |> Enum.sort()

    sample_size = length(permutation_data)

    quantiles =
      for quantile <- [0.25, 0.5, 0.75],
          do: {quantile, percentile(permutation_data, sample_size, quantile)},
          into: %{}

    interquartile_range = quantiles[0.75] - quantiles[0.25]
    ymin_threshold = quantiles[0.25] - 1.5 * interquartile_range
    ymax_threshold = quantiles[0.75] + 1.5 * interquartile_range

    outliers =
      for record <- permutation_data,
          record > ymax_threshold or record < ymin_threshold,
          do: record

    %{
      ymin:
        Enum.filter(permutation_data, fn record -> record >= ymin_threshold end) |> Enum.min(),
      lower: quantiles[0.25],
      middle: quantiles[0.5],
      upper: quantiles[0.75],
      ymax:
        Enum.filter(permutation_data, fn record -> record <= ymax_threshold end) |> Enum.max(),
      outliers: outliers
    }
  end

  defp percentile([single_value], 1, _percentile), do: single_value

  defp percentile(data, sample_size, percentile) when percentile >= 0 and percentile <= 1 do
    p = percentile * (sample_size - 1) + 1
    k = trunc(p)
    d = p - k
    {_first_half, [lower, upper | _rest_of_second_half]} = Enum.split(data, k - 1)
    lower + d * (upper - lower)
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

  defp permutations(discrete_aesthetics, data, mapping) do
    for row <- data,
        uniq: true,
        do:
          discrete_aesthetics
          |> Enum.map(fn aesthetic -> {aesthetic, row[mapping[aesthetic]]} end)
          |> Map.new()
  end
end
