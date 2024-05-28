from datetime import datetime


def aws_glue_job_args_mock():
    """Fixture for simulating AWS Glue job arguments."""
    current_time = datetime.now()
    stage = "dev"
    return [
        "convert_csv_to_parque_glue_job.py",  # sys.argv[0], script name
        "true",
        "--is_local",
        "true",
        "--job-bookmark-option",
        "job-bookmark-disable",
        "--JOB_ID",
        "j_a197e5a4ae431ff7631a35bdcddbb8b6bebf747667c548020bfbd40447569b25",
        "true",
        "--stage",
        "dev",
        "--JOB_RUN_ID",
        "jr_6a23882f8589db824567693a787ec1014a66dcc868186c2cb8ae26a502f47040",
        "--JOB_NAME",
        "TEST_JOB",
        "--execution_arn",
        f"arn:aws:states:eu-west-1:625904187796:execution:TEST_JOB:try-{current_time.strftime('%Y%m%d%H%M%S%f')}",
        "--job",
        "job_name",
        "--zone",
        "TEST",
        "--debugging",
        "True",
        "--source_type",
        "BP",
        "--data_source",
        "SILVER",
        "--sp_name",
        "my_sp",
        "--stage",
        stage,
        "--log_group_name",
        f"/aws-glue/jobs/convert-csv-to-parque-glue-job-{stage}",
    ]
