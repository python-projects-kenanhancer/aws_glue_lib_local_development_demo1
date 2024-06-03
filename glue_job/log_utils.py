import boto3
import time
import watchtower
import logging


class LogUtils:
    def __init__(
        self,
        log_group_name: str,
        log_stream_name: str,
        job_name: str,
        execution_arn: str,
    ):
        # Create a CloudWatchLogs client
        self.cw_logs = boto3.client("logs")
        self.log_group_name = log_group_name
        self.log_stream_name = log_stream_name
        self.job_name = job_name
        self.execution_arn = execution_arn

    def configure_logging(self):

        logging.basicConfig(level=logging.INFO)

        # Add CloudWatch handler
        cw_handler = watchtower.CloudWatchLogHandler(
            log_group=self.log_group_name,
            stream_name=self.log_stream_name,
            boto3_client=self.cw_logs,
        )

        log_format = f"[%(levelname)s]\t%(message)s\t{self.job_name}\t{self.log_stream_name}\t{self.execution_arn}"
        formatter = logging.Formatter(log_format)
        cw_handler.setFormatter(formatter)

        # Add the handler to the root logger
        logging.getLogger().addHandler(cw_handler)

    def create_cloud_watch_log_group(self):
        # Check if the log stream already exists within the log group
        log_streams = self.cw_logs.describe_log_streams(
            logGroupName=self.log_group_name, logStreamNamePrefix=self.log_stream_name
        )
        if not any(
            ls["logStreamName"] == self.log_stream_name
            for ls in log_streams["logStreams"]
        ):
            # Log stream doesn't exist, so create it
            self.cw_logs.create_log_stream(
                logGroupName=self.log_group_name, logStreamName=self.log_stream_name
            )
            print(f"Log stream '{self.log_stream_name}' created.")
        else:
            print(f"Log stream '{self.log_stream_name}' already exists.")


def log_operation(operation_name, func):
    start_time = time.time()
    try:
        logging.info(f"Starting operation: {operation_name}")
        func()
        logging.info(
            f"Completed operation: {operation_name} in {time.time() - start_time:.2f} seconds"
        )
    except Exception as e:
        logging.error(
            f"Error during operation: {operation_name} - {str(e)}", exc_info=True
        )
