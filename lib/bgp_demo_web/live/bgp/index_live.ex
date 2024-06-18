defmodule BGPDemoWeb.BGP.IndexLive do
  require Logger
  use BGPDemoWeb, :live_view

  @servers [BGPDemo.ASN64496A, BGPDemo.ASN64496B, BGPDemo.ASN65536A, BGPDemo.ASN65536B]

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div id="bgp_demo" class="h-dvh" phx-hook="Chart">
      <div id="bgp_demo-chart" class="h-full w-full" phx-update="ignore" />
      <div id="bgp_demo-data" hidden><%= Jason.encode!(@option) %></div>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    servers = Enum.map(@servers, &BGP.Server.get_config/1)

    if connected?(socket) do
      :telemetry.attach(
        "bgp-looking-glass",
        [:bgp, :session, :state],
        &__MODULE__.telemetry_handler/4,
        %{dest: self()}
      )

      for server <- servers, do: BGP.Server.start_link(server[:server])
    end

    option =
      %{
        title: %{
          text: "BGP Simulation",
          top: "top",
          left: "left"
        },
        tooltip: %{},
        legend: [
          %{
            data: Enum.map(servers, &to_string(&1[:asn])) |> Enum.uniq() |> Enum.map(&%{name: &1})
          }
        ],
        series: [
          %{
            name: "BGP",
            type: "graph",
            layout: "force",
            nodes:
              Enum.map(servers, fn server ->
                %{
                  category: to_string(server[:asn]),
                  id: to_string(server[:bgp_id]),
                  name: to_string(server[:bgp_id]),
                  value: server[:server] |> Module.split() |> List.last(),
                  symbolSize: 10
                }
              end),
            edges: [],
            categories:
              Enum.map(servers, &to_string(&1[:asn])) |> Enum.uniq() |> Enum.map(&%{name: &1}),
            roam: true,
            label: %{
              position: "right"
            },
            lineStyle: %{
              color: "source",
              curveness: 0.1
            },
            force: %{
              repulsion: 100
            }
          }
        ]
      }

    {:ok, assign(socket, option: option)}
  end

  @impl Phoenix.LiveView
  def handle_info(
        {[:bgp, :session, :state], %{state: state}, %{peer: peer, server: server}},
        socket
      ) do
    source = to_string(BGP.Server.get_config(server)[:bgp_id])
    target = to_string(peer)

    type =
      case state do
        :idle -> :dotted
        :established -> :solid
        _state -> :dashed
      end

    option =
      update_in(socket.assigns.option, [:series, Access.at(0), :edges], fn edges ->
        [
          %{
            source: source,
            target: target,
            value: state |> to_string() |> String.upcase(),
            label: %{show: true},
            lineStyle: %{type: type}
          }
          | Enum.reduce(edges, [], fn
              %{source: ^source, target: ^target}, acc -> acc
              link, acc -> [link | acc]
            end)
        ]
      end)

    {:noreply, assign(socket, :option, option)}
  end

  def handle_info(_msg, socket) do
    {:noreply, socket}
  end

  @doc false
  def telemetry_handler(event, measurements, metadata, config) do
    send(config.dest, {event, measurements, metadata})
    :ok
  end
end
