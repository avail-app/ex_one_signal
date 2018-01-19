ExUnit.start()
Application.ensure_all_started(:bypass)

Application.put_env(:ex_one_signal, ExOneSignal, [
  app_id: "test_id",
  api_key: "test_key"
])
