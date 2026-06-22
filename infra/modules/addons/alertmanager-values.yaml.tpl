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
      receiver: slack-notifications
      routes:
        - receiver: "null"
          matchers:
            - alertname=~"InfoInhibitor|Watchdog"
    receivers:
      - name: "null"
      - name: slack-notifications
        slack_configs:
          - api_url: "${webhook_url}"
            channel: "#alerts"
            send_resolved: true
