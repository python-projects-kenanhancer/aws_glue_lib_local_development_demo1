import boto3
import watchtower
import logging


def setup_cloudwatch_logging(log_group_name: str, log_stream_name: str, job_name: str, execution_arn: str):
    # Create a CloudWatchLogs client
    cw_logs = boto3.client("logs")

    # Check if the log stream already exists within the log group
    log_streams = cw_logs.describe_log_streams(
        logGroupName=log_group_name, logStreamNamePrefix=log_stream_name
    )
    if not any(
        ls["logStreamName"] == log_stream_name for ls in log_streams["logStreams"]
    ):
        # Log stream doesn't exist, so create it
        cw_logs.create_log_stream(
            logGroupName=log_group_name, logStreamName=log_stream_name
        )
        print(f"Log stream '{log_stream_name}' created.")
    else:
        print(f"Log stream '{log_stream_name}' already exists.")

    logging.basicConfig(level=logging.INFO)

    # Add CloudWatch handler
    cw_handler = watchtower.CloudWatchLogHandler(
        log_group=log_group_name, stream_name=log_stream_name, boto3_client=cw_logs
    )

    log_format = (
        f"[%(levelname)s]\t%(message)s\t{job_name}\t{log_stream_name}\t{execution_arn}"
    )
    formatter = logging.Formatter(log_format)
    cw_handler.setFormatter(formatter)

    # Add the handler to the root logger
    logging.getLogger().addHandler(cw_handler)
