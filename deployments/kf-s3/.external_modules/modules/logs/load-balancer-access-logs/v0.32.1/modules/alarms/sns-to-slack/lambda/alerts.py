import datetime
import json
import logging
import os
import time

from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

COLORS = ['good', 'warning', 'danger']
GREEN, YELLOW, RED = COLORS

OK = 'OK'
ALARM = 'ALARM'

BOT_NAME = 'GruntBot'
BOT_FAVICON = 'http://www.gruntwork.io/assets/img/favicon/favicon-32x32.png'

SLACK_WEBHOOK_URL = os.environ.get('SLACK_WEBHOOK_URL', False)


def datetime_to_unix(dt):
    """Converts a datetime object to a unix time (seconds from epoch)"""
    return int(time.mktime(dt.timetuple()))


def parse_iso_8601(iso_string):
    """Convert an ISO 8601 string such as `2017-03-28T19:52:00.391Z` into a native datetime."""
    return datetime.datetime.strptime(iso_string, "%Y-%m-%dT%H:%M:%S.%fZ")


def make_field(title, value, short=True):
    return {'title': title, 'value': value, 'short': short}


class BaseNotification(object):
    @classmethod
    def from_lambda_event(cls, event):
        return cls(event['Records'][0]['Sns'])

    def __init__(self, body):
        self.body = body

    @property
    def subject(self):
        return self.body['Subject']

    @property
    def message(self):
        msg = self.body['Message']
        return json.loads(msg)

    @property
    def timestamp(self):
        return parse_iso_8601(self.body.get('Timestamp'))

    @property
    def ts(self):
        return datetime_to_unix(self.timestamp)


class CloudWatchNotification(BaseNotification):
    """
  A notification that attempts to utilize the more advanced formatting
  capabilities of Slack to display relevant CloudWatch alarm information.

  """
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

    @property
    def name(self):
        return self.message.get('AlarmName')

    @property
    def new_state_reason(self):
        return self.message.get('NewStateReason')

    @property
    def state(self):
        return self.message.get('NewStateValue')

    @property
    def color(self):
        if self.state == ALARM:
            return RED
        return GREEN

    @property
    def region(self):
        return self.message.get('Region')

    @property
    def description(self):
        return self.message.get('AlarmDescription')

    @property
    def href(self):
        tmpl = 'https://console.aws.amazon.com/cloudwatch/home?region={region}#alarm:alarmFilter=ANY;name={alarm_name}'
        return tmpl.format(region=self.region, alarm_name=self.name)

    @property
    def attachment(self):
        return {
            "pretext":
            self.subject,
            "text":
            self.new_state_reason,
            "color":
            self.color,
            "fields": [
                make_field('Description', self.description, short=False),
                make_field('Region', self.region),
                make_field('Occurred', "%s UTC" % self.timestamp.isoformat()),
                make_field('Link', self.href, short=False)
            ],
            "ts":
            self.ts,
            "footer":
            BOT_NAME,
            "footer_icon":
            BOT_FAVICON,
        }

    @property
    def slack_payload(self):
        return {'attachments': [self.attachment]}


class SimpleNotification(BaseNotification):
    """A simplified Slack notification that displays the entire JSON message in an indented code format."""
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

    @property
    def markdown_text(self):
        return """```{}
    ```""".format(json.dumps(self.message, indent=2))

    @property
    def attachment(self):
        return {
            'pretext': self.subject,
            'text': self.markdown_text,
            'mrkdwn_in': ['text'],
            'ts': self.ts,
            'footer': BOT_NAME,
            'footer_icon': BOT_FAVICON,
        }

    @property
    def slack_payload(self):
        return {'attachments': [self.attachment]}


def post_to_slack(body):
    if not SLACK_WEBHOOK_URL:
        raise Exception(
            'Please define the environment variable SLACK_WEBHOOK_URL')

    req = Request(SLACK_WEBHOOK_URL, json.dumps(body).encode('utf-8'))

    try:
        response = urlopen(req)
        response.read()
        logger.info('Message posted to Slack')
        return response

    # We reraise the exception so that the lambda function halts execution with an error when we fail to post to slack.
    except HTTPError as e:
        logger.error('Request failed: %d %s', e.code, e.reason)
        raise e

    except URLError as e:
        logger.error('Server connection failed: %s', e.reason)
        raise e


def handler(event, context):
    logger.info('Handling event: %s', json.dumps(event))

    notification = SimpleNotification.from_lambda_event(event)
    response = post_to_slack(notification.slack_payload)

    logger.info(
        json.dumps({
            'headers': dict(response.info().items()),
            'status_code': response.getcode()
        }))

    return True
