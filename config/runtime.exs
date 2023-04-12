import Config

config :netim,
  url: System.get_env("NETIM_URL"),
  id_reseller: System.get_env("NETIM_ID_RESELLER"),
  password: System.get_env("NETIM_PASSWORD")
