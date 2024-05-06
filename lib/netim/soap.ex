defmodule Netim.Soap do
  @moduledoc """
  Documentation for `Netim`.
  """

  @namespace "urn:DRS"

  @doc """
  Create the base SOAP request for Netim. We provide the name of the method
  to be called and the list of arguments.
  """
  @spec base(String.t(), [any()]) :: Soap.t()
  def base(method, args) do
    method
    |> Soap.new(args, @namespace)
    |> Soap.set_soap_action(method)
  end

  @doc """
  Perform the SOAP call. It requires a populated SOAP struct.
  """
  @spec request(Soap.t()) :: {:ok, map()} | {:error, any()}
  def request(soap) do
    url = Application.get_env(:netim, :url)
    Soap.Client.request(url, soap)
  end
end
