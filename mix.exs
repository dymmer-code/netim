defmodule Netim.MixProject do
  use Mix.Project

  @version "0.2.0"
  @source_url "https://github.com/dymmer/netim"

  def project do
    [
      app: :netim,
      version: @version,
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: dialyzer(),
      package: package(),
      docs: docs(),
      preferred_cli_env: [
        check: :test
      ]
    ]
  end

  defp dialyzer do
    [
      plt_local_path: ".plts",
      plt_core_path: ".plts",
      plt_add_apps: [:inets, :ssl, :public_key, :logger],
      flags: [:error_handling, :unknown]
    ]
  end

  defp package do
    [
      files: ~w(lib mix.exs README* COPYING* LICENSE* .formatter.exs),
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: ["README.md", "COPYING"]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      extra_applications: [:logger, :inets, :ssl, :public_key],
      mod: {Netim.Application, []}
    ]
  end

  defp deps do
    [
      {:soap, github: "altenwald/soap-elixir"},
      {:countries, "~> 1.6"},
      {:money, "~> 1.12"},
      {:typed_ecto_schema, "~> 0.4"},
      {:ecto, "~> 3.9"},
      {:whois, "~> 0.3"},
      {:passby, "~> 0.1", only: :test},

      # only for dev
      {:dialyxir, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:credo, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:doctor, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:ex_check, "~> 0.14", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:mix_audit, ">= 0.0.0", only: [:dev, :test], runtime: false}
    ]
  end
end
