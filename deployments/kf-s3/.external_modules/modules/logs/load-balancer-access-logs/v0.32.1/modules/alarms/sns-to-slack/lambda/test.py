import json
import os
import pprint
import sys

from alerts import *

CURRENT_DIR = os.path.dirname(os.path.realpath(__file__))
TEST_DATA = os.path.join(CURRENT_DIR, 'test-data')


def notification_factory():
    return SimpleNotification


def load_fixture(filename, transformation=lambda x: x):
    with open(os.path.join(TEST_DATA, filename), 'r+') as f:
        content = f.read()
        return transformation(content)


def transform(s):
    x = s.replace('\r\n', '').replace('\\"', r'\"')
    return json.loads(x)


def is_json(f):
    return os.path.isfile(f) and f.endswith('json')


def lambda_event_fixtures():
    paths = filter(is_json,
                   [os.path.join(TEST_DATA, f) for f in os.listdir(TEST_DATA)])
    return [load_fixture(p, transformation=transform) for p in paths]


def slack_payloads():
    for lambda_event in lambda_event_fixtures():
        notification = notification_factory().from_lambda_event(lambda_event)
        yield notification.slack_payload


def test_slack():
    """
  Useful for debugging:
    - Run all event fixture data through system
    - Post each event to Slack

  """
    for p in slack_payloads():
        print("Posting notification to Slack")
        pprint.pprint(p)

        r = post_to_slack(p)
        print(r.getcode())
        print()


def test_print():
    """
  Useful for debugging:
    - Run all event fixture data through system
    - Print the output

  """
    for p in slack_payloads():
        pprint.pprint(p)
        print()


def test_lambda():
    """
  Using fixture data, run the *actual* lambda event handler directly
  to emulate the actual aws/lambda environment as closely as possible

  """
    for event in lambda_event_fixtures():
        print(handler(event, 'foo'))


if __name__ == '__main__':
    valid_commands = {
        'slack': test_slack,
        'print': test_print,
        'lambda': test_lambda
    }

    def show_instructions():
        print("Please specify a command: %s" % ', '.join(valid_commands))
        sys.exit()

    if len(sys.argv) is 1:
        show_instructions()

    cmd = sys.argv[1]

    if cmd not in valid_commands:
        show_instructions()

    # Do the thing
    valid_commands.get(cmd)()
