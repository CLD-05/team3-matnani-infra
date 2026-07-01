alertmanager:
  config:
    global:
      resolve_timeout: 5m
    route:
      group_by:
        - alertname
        - namespace
      group_wait: 30s
      group_interval: 5m
      repeat_interval: 12h
      receiver: "null"
    receivers:
      - name: "null"
