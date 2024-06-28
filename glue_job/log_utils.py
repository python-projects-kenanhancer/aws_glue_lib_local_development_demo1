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
        environment=None,
    ):
        # Create a CloudWatchLogs client
        self.cw_logs = boto3.client("logs")
        self.log_group_name = log_group_name
        self.log_stream_name = log_stream_name
        self.job_name = job_name
        self.execution_arn = execution_arn
        self.environment = environment

    def _is_handler_exists(self, handler_type):
        root_logger = logging.getLogger()
        return any(isinstance(h, handler_type) for h in root_logger.handlers)

    def _get_or_create_console_handler(self):
        root_logger = logging.getLogger()
        for handler in root_logger.handlers:
            if isinstance(handler, logging.StreamHandler):
                return handler

        console_log_handler = logging.StreamHandler()
        root_logger.addHandler(console_log_handler)
        return console_log_handler

    def configure_logging(self):
        # logging.basicConfig(level=logging.INFO)
        root_logger = logging.getLogger()
        root_logger.setLevel(logging.INFO)  # Set root logger level to INFO

        log_format = f"[%(levelname)s]\t%(message)s\t{self.job_name}\t{self.log_stream_name}\t{self.execution_arn}"
        formatter = logging.Formatter(log_format)

        if self.environment == "local":
            console_log_handler = self._get_or_create_console_handler()
            console_log_handler.setLevel(logging.INFO)
            console_log_handler.setFormatter(formatter)
        else:
            if not self._is_handler_exists(watchtower.CloudWatchLogHandler):
                cw_log_handler = watchtower.CloudWatchLogHandler(
                    log_group=self.log_group_name,
                    stream_name=self.log_stream_name,
                    boto3_client=self.cw_logs,
                )
                cw_log_handler.setFormatter(formatter)

                # Add AWS CloudWatch Log Handler to the root logger
                root_logger.addHandler(cw_log_handler)

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
            logging.info(f"Log stream '{self.log_stream_name}' created.")
        else:
            logging.info(f"Log stream '{self.log_stream_name}' already exists.")


def log_operation(operation_name, func, exception_callback):
    start_time = time.time()
    try:
        logging.info(f"Starting operation: {operation_name}")
        func()
        logging.info(
            f"Completed operation: {operation_name} in {time.time() - start_time:.2f} seconds"
        )
    except Exception as e:
        message = f"Error during operation: {operation_name} - {str(e)}"
        logging.error(message, exc_info=True)
        if exception_callback:
            exception_callback(message, e)
