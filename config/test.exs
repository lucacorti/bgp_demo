import Config

config :bgp_demo, BGPDemo.TestServerA,
  asn: 64_496,
  bgp_id: "172.16.1.3",
  networks: ["12.12.0.0/20"],
  port: 60_179,
  peers: [
    [
      asn: 65_536,
      connect_retry: [seconds: 5],
      bgp_id: "172.16.1.4",
      host: "127.0.0.1"
    ]
  ]

config :bgp_demo, BGPDemo.TestServerB,
  asn: 65_536,
  bgp_id: "172.16.1.4",
  networks: ["13.12.0.0/20"],
  port: 60_180,
  peers: [
    [
      asn: 64_496,
      connect_retry: [seconds: 5],
      bgp_id: "172.16.1.3",
      host: "127.0.0.1"
    ]
  ]

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :bgp_demo, BGPDemoWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "L8F2hBpqzDV4AjWku7dkWbB8T4tmFLCCxUuVlc+akeMEUXEgFobyhzxFn7emq3OT",
  server: false

# In test we don't send emails.
config :bgp_demo, BGPDemo.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

config :phoenix_live_view,
  # Enable helpful, but potentially expensive runtime checks
  enable_expensive_runtime_checks: true
