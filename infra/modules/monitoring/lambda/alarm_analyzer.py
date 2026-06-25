import json
import boto3
import urllib.request
import os

BEDROCK_MODEL_ID = "anthropic.claude-3-5-haiku-20241022-v1:0"
REGION = "ap-northeast-2"


def lambda_handler(event, context):
    for record in event.get("Records", []):
        sns_message = json.loads(record["Sns"]["Message"])
        analyze_alarm(sns_message)


def analyze_alarm(sns_message):
    alarm_name = sns_message.get("AlarmName", "")
    alarm_description = sns_message.get("AlarmDescription", "")
    new_state = sns_message.get("NewStateValue", "")
    reason = sns_message.get("NewStateReason", "")
    trigger = sns_message.get("Trigger", {})

    if new_state != "ALARM":
        return

    prompt = f"""당신은 AWS 인프라 전문가입니다. 아래 CloudWatch 알람 정보를 분석하고 한국어로 답변해주세요.

알람명: {alarm_name}
설명: {alarm_description}
상태: {new_state}
발생 원인: {reason}
메트릭: {trigger.get("MetricName", "")} / {trigger.get("Namespace", "")}
임계값: {trigger.get("Threshold", "")}

다음 형식으로 간결하게 분석해주세요:
1. 상황 요약 (1-2문장)
2. 예상 원인
3. 즉시 조치 방법
4. 재발 방지 방안"""

    bedrock = boto3.client("bedrock-runtime", region_name=REGION)
    response = bedrock.invoke_model(
        modelId=BEDROCK_MODEL_ID,
        body=json.dumps({
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": 800,
            "messages": [{"role": "user", "content": prompt}]
        })
    )
    analysis = json.loads(response["body"].read())["content"][0]["text"]

    slack_webhook = os.environ["SLACK_WEBHOOK_URL"]
    slack_message = {
        "blocks": [
            {
                "type": "header",
                "text": {"type": "plain_text", "text": f"🔴 AI 장애 분석: {alarm_name}"}
            },
            {
                "type": "section",
                "text": {"type": "mrkdwn", "text": f"*원인:* {reason[:300]}"}
            },
            {"type": "divider"},
            {
                "type": "section",
                "text": {"type": "mrkdwn", "text": f"*🤖 Claude 분석*\n{analysis}"}
            }
        ]
    }

    req = urllib.request.Request(
        slack_webhook,
        data=json.dumps(slack_message).encode(),
        headers={"Content-Type": "application/json"}
    )
    urllib.request.urlopen(req)
