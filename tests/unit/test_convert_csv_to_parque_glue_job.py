import pytest
from .test_mock import aws_glue_job_args_mock


class TestConvertCsvToParqueGlueJob:
    @pytest.fixture
    def aws_glue_job_args(self):
        """Fixture for simulating AWS Glue job arguments."""
        return aws_glue_job_args_mock()

    def test_convert_csv_to_parque_glue_job(self, monkeypatch, aws_glue_job_args):
        monkeypatch.setattr("sys.argv", aws_glue_job_args)
        monkeypatch.setenv("JOB_NAME", None)

        # Activate Python Virtual Environment and run command: `jupyter nbconvert --to script convert_csv_to_parque_glue_job.ipynb` in terminal.
        #
        # The AWS Glue job script (convert_csv_to_parque_glue_job.py) is executed when imported
        from ...glue_job import (
            args,
        )  # Import the script/module to test

        # Now 'args' is populated as it would be in an AWS Glue environment
        assert args["JOB_NAME"] == "test_job"
