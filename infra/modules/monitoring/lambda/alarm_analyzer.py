import json
import os
import urllib.request

import boto3

BEDROCK_MODEL_ID = os.environ.get(
    "BEDROCK_MODEL_ID",
    "anthropic.claude-3-haiku-20240307-v1:0",
)
REGION = os.environ.get("AWS_REGION", "ap-northeast-2")

bedrock = boto3.client("bedrock-runtime", region_name=REGION)


def lambda_handler(event, context):
    for record in event.get("Records", []):
        message = record.get("Sns", {}).get("Message", "{}")
        try:
            sns_message = json.loads(message)
        except json.JSONDecodeError:
            sns_message = {"raw_message": message}
        analyze_alarm(sns_message)

    return {"statusCode": 200}


def analyze_alarm(sns_message):
    alarm_name = sns_message.get("AlarmName", "unknown-alarm")
    alarm_description = sns_message.get("AlarmDescription", "")
    new_state = sns_message.get("NewStateValue", "")
    reason = sns_message.get("NewStateReason", "")
    trigger = sns_message.get("Trigger", {}) or {}

    if new_state != "ALARM":
        return

    analysis = invoke_claude(
        alarm_name=alarm_name,
        alarm_description=alarm_description,
        reason=reason,
        trigger=trigger,
    )
    send_slack_message(
        alarm_name=alarm_name,
        alarm_description=alarm_description,
        reason=reason,
        trigger=trigger,
        analysis=analysis,
    )


def invoke_claude(alarm_name, alarm_description, reason, trigger):
    prompt = f"""
You are an SRE assistant for the team3 matnani service.
Analyze this AWS CloudWatch alarm and write a concise Korean incident diagnosis.
Do not claim that any remediation was executed.
Recommend actions only as operator-approved suggestions.

Alarm name: {alarm_name}
Description: {alarm_description}
Reason: {reason}
Metric: {trigger.get("MetricName", "")} / {trigger.get("Namespace", "")}
Threshold: {trigger.get("ComparisonOperator", "")} {trigger.get("Threshold", "")}

Please answer in Korean using this format:
1. Situation summary
2. Likely causes
3. Checks to perform now
4. Operator-approved actions
"""

    try:
        response = bedrock.invoke_model(
            modelId=BEDROCK_MODEL_ID,
            body=json.dumps({
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": 900,
                "messages": [{"role": "user", "content": prompt}],
            }),
        )
        return json.loads(response["body"].read())["content"][0]["text"]
    except Exception as exc:
        return (
            "Claude analysis failed. Check the alarm details manually.\n"
            f"Error: {exc}"
        )


def send_slack_message(alarm_name, alarm_description, reason, trigger, analysis):
    slack_webhook = os.environ["SLACK_WEBHOOK_URL"]
    metric_name = trigger.get("MetricName", "")
    namespace = trigger.get("Namespace", "")
    threshold = trigger.get("Threshold", "")
    comparison = trigger.get("ComparisonOperator", "")

    slack_message = {
        "blocks": [
            {
                "type": "header",
                "text": {
                    "type": "plain_text",
                    "text": f"AIOps analysis: {alarm_name}"[:150],
                },
            },
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": (
                        f"*State:* ALARM\n"
                        f"*Metric:* `{namespace} / {metric_name}`\n"
                        f"*Threshold:* `{comparison} {threshold}`"
                    ),
                },
            },
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"*Description*\n{alarm_description or '-'}",
                },
            },
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"*Reason*\n{reason[:800] or '-'}",
                },
            },
            {"type": "divider"},
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": (
                        "*Action policy*\n"
                        "- This Lambda does not run automatic recovery.\n"
                        "- Any restart, rollback, scaling, or infrastructure change requires operator approval."
                    ),
                },
            },
            {"type": "divider"},
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"*Claude diagnosis*\n{analysis[:2500]}",
                },
            },
        ]
    }

    req = urllib.request.Request(
        slack_webhook,
        data=json.dumps(slack_message).encode(),
        headers={"Content-Type": "application/json"},
    )
    urllib.request.urlopen(req, timeout=10)
