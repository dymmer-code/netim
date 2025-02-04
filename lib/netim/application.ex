defmodule Netim.Application do
  @moduledoc """
  The application module has the mission to start a supervisor to manage the
  product cache. At the moment, the product cache is the only process that
  needs to be supervised.
  """
  use Application

  @impl Application
  def start(_start_type, _start_args) do
    children = [
      Netim.Tld.PriceCache
    ]

    opts = [strategy: :one_for_one, name: Netim.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
