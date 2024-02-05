defmodule BitrixEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :bitrix_ex,
      description: description(),
      package: package(),
      releases: releases(),
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      docs: docs(),
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.cobertura": :test
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description do
    "HTTP client make using Tesla for integrating with the Bitrix24 API"
  end

  defp package do
    [
      maintainers: ["JVMartyns"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/JVMartyns/bitrix_ex"}
    ]
  end

  defp releases do
    [
      bitrix_ex: [
        include_executables_for: [:unix],
        steps: [:assemble, :tar]
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:tesla, "~> 1.8.0"},
      {:jason, ">= 1.0.0"},
      {:hackney, "~> 1.17.0"},
      {:telemetry, "~> 0.4 or ~> 1.0"},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: :test}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      source_url: "https://github.com/JVMartyns/bitrix_ex"
    ]
  end
end
