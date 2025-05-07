import os

if os.environ.get('REY_INIT_API', 'false') == 'true':
    from datadog_lambda.api import init_api
    init_api()

cold_start = True

def handler(event, context):
    global cold_start

    if cold_start:
        from datadog_lambda.cold_start import root_nodes
        from datadog_lambda.metric import lambda_metric

        start = root_nodes[0].start_time_ns
        end = root_nodes[-1].end_time_ns

        lambda_metric('rey.aws.lambda.load', end - start)

    cold_start = False
    return 'ok'
