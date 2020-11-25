defmodule GGity.MixProject do
  use Mix.Project

  def project do
    [
      app: :ggity,
      version: "0.3.0",
      aliases: aliases(),
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      package: package(),
      deps: deps(),
      dialyzer: [plt_add_apps: [:mix]],
      name: "GGity",
      description: "GGity brings the familiar interface of R's ggplot2 library to SVG charting in Elixir.",
      source_url: "https://github.com/srowley/ggity",
      homepage_url: "http://www.pocketbookvote.com",
      licenses: "MIT",
      docs: [
        extras: ["README.md", "ROADMAP.md"],
        main: "readme"
      ]
    ]
  end

  def application, do: []

  defp deps do
    [
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: :dev, runtime: false},
      {:ex_doc, "~> 0.22", only: :dev, runtime: false},
      {:sweet_xml, "~> 0.6.6", only: :test},
      {:nimble_csv, "~> 0.7"},
      {:nimble_strftime, "~> 0.1"}
    ]
  end

  defp aliases do
    [
      checks: [
        "compile",
        "credo",
        "dialyzer",
        "format",
        "ggity.visual"
      ]
    ]
  end

  defp package() do
    [
      name: "ggity",
      files: ~w(lib priv mix.exs README* LICENSE* ROADMAP* CHANGELOG*),
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/srowley/ggity",
        "Website" => "http://www.pocketbookvote.com/"
      }
    ]
  end
end
