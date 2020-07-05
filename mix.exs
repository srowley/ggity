defmodule GGity.MixProject do
  use Mix.Project

  def project do
    [
      app: :ggity,
      version: "0.2.0",
      aliases: aliases(),
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [plt_add_apps: [:mix]],
      name: "GGity",
      source_url: "https://github.com/srowley/ggity",
      docs: [
        extras: ["README.md", "ROADMAP.md"]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.3", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: :dev, runtime: false},
      {:ex_doc, "~> 0.22", only: :dev, runtime: false},
      {:sweet_xml, "~> 0.6.6", only: :test},
      {:nimble_csv, "~> 0.7", only: [:dev, :test]},
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
end
