defmodule BGPDemoWeb.BGP.IndexLive do
  use BGPDemoWeb, :live_view

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
    :telemetry.attach(
      "bgp-looking-glass",
      [:bgp, :session, :state],
      &__MODULE__.telemetry_handler/4,
      %{dest: self()}
    )

    servers =
      Enum.map(
        [BGPDemo.ASN64496_1, BGPDemo.ASN64496_2, BGPDemo.ASN65536_1, BGPDemo.ASN65536_2],
        &BGP.Server.get_config/1
      )

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
            # selectedMode: "single",
            data: Enum.map(servers, &to_string(&1[:asn])) |> Enum.uniq()
          }
        ],
        series: [
          %{
            name: "BGP",
            type: "graph",
            layout: "force",
            data:
              Enum.map(servers, fn server ->
                %{
                  category: to_string(server[:asn]),
                  id: to_string(server[:bgp_id]),
                  name: to_string(server[:bgp_id]),
                  value: "AS" <> to_string(server[:asn]),
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

    option =
      if source != target do
        update_in(socket.assigns.option, [:series, Access.at(0), :edges], fn edges ->
          [
            %{source: source, target: target, value: state}
            | Enum.reduce(edges, [], fn
                %{source: ^source, target: ^target}, acc -> acc
                link, acc -> [link | acc]
              end)
          ]
        end)
      else
        socket.assigns.option
      end

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
