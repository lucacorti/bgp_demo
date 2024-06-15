defmodule BGPDemo.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      BGPDemoWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:bgp_demo, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: BGPDemo.PubSub},
      {Finch, name: BGPDemo.Finch},
      BGPDemoWeb.Endpoint,
      {BGP.Server, BGPDemo.ASN64496_1},
      {BGP.Server, BGPDemo.ASN64496_2},
      {BGP.Server, BGPDemo.ASN65536_1},
      {BGP.Server, BGPDemo.ASN65536_2}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BGPDemo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    BGPDemoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
