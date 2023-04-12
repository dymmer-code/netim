defmodule Netim do
  @moduledoc """
  Documentation for `Netim`.
  """

  @namespace "urn:DRS"

  def base(method, args) do
    method
    |> Soap.new(args, @namespace)
    |> Soap.set_soap_action(method)
  end

  def request(soap) do
    url = Application.get_env(:netim, :url)
    Soap.Client.request(url, soap)
  end
end
