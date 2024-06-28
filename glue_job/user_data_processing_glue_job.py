#!/usr/bin/env python
# coding: utf-8

# Local Development prerequisites
# 
# - Run `source ./setup_aws_glue_scripts/setup_aws_glue.sh` in GitBash
# 
# AWS Glue Local Debugging:
# > Run `./glue_local_debug.sh` or follow the following steps.
# 
# - From the Command Palette (`Ctrl+Shift+P`), select `Tasks: Run Task command`, then select `Convert Notebook to Script`
# - Run `pipenv shell` in terminal
# - Run `jupyter notebook --no-browser` in terminal
# - Copy Jupyter Server url from terminal
# - From the Command Palette (`Ctrl+Shift+P`), select `Notebook: Select Notebook Kernel`, then select `Select Another Kernel...`, then select `Existing Jupyter Server...`, then paste Jupyter Server url, then enter, then enter again.
# 
# AWS Glue Interactive Session Debugging:
# - From the Command Palette (`Ctrl+Shift+P`), select `Tasks: Run Task command`, then select `Convert Notebook to Script`
# - Run `pipenv shell` in terminal
# - Run `jupyter notebook --no-browser` in terminal
# - Copy Jupyter Server url from terminal
# - From the Command Palette (`Ctrl+Shift+P`), select `Notebook: Select Notebook Kernel`, then select `Select Another Kernel...`, then select `Existing Jupyter Server...`, then paste Jupyter Server url, then enter, then enter again.
# - Uncomment the following cell, and run it.

# # To configure AWS Glue Interactive Session, uncomment the following cell
# 
# Change configuration in terms of your requirements.

# In[ ]:


# %profile [your-profile-name]
# %region eu-west-1
# %iam_role [your-iam-role]
# %worker_type G.1X
# %number_of_workers 2
# %additional_python_modules watchtower
# %extra_py_files s3://artifacts-dev/33333/Layers/pip_common_packages_layer_glue.zip,s3://artifacts-dev/33333/Layers/combined_lambda_layer_glue.zip


# # To pass system arguments, uncomment the following cell
# 
# Change arguments in terms of your requirements.

# In[ ]:


import os
import sys
from datetime import datetime


stage = os.environ.get("STAGE", "dev")
current_time = datetime.now()

sys.argv = [
    "user_data_processing_glue_job.py",  # sys.argv[0], script name
    "--JOB_ID", "j_a197e5a4ae431ff7631a35bdcddbb8b6bebf747667c548020bfbd40447569b25",
    "--JOB_RUN_ID", "jr_6a23882f8589db824567693a787ec1014a66dcc868186c2cb8ae26a502f47040",
    "--JOB_NAME", "TEST_JOB",
    "--execution_arn", f"arn:aws:states:eu-west-1:625904187796:execution:TEST_JOB:try-{current_time.strftime('%Y%m%d%H%M%S%f')}",
    "--job", "job_name",
    "--stage", stage,
    "--log_group_name", f"/aws-glue/jobs/user_data_processing_glue_job_{stage}",
]


# # Initialize AWS Glue Context

# In[ ]:


import os
import sys
import json
import logging

from log_utils import LogUtils, log_operation

from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job


# Get parameters passed to the script
args = getResolvedOptions(
    sys.argv,
    [
        "JOB_NAME",
        "job",
        "execution_arn",
        "log_group_name",
        "stage",
    ],
)

env = os.environ.get("ENV")
log_utils = LogUtils(
    log_group_name=args["log_group_name"],
    log_stream_name=args["JOB_RUN_ID"],
    job_name=args["job"],
    execution_arn=args["execution_arn"],
    environment=env
)

log_utils.configure_logging()

logger = logging.getLogger()

# Initialize Glue context
sparkContext = SparkContext.getOrCreate()
glueContext = GlueContext(sparkContext=sparkContext)
spark = glueContext.spark_session
# logger = glueContext.get_logger()
job = Job(glueContext)
job.init(args["JOB_NAME"], args)


# # To Print System Arguments

# In[ ]:


logging.info(f"sys.argv to json: {json.dumps(obj=sys.argv, indent=4)}")
logging.info(f"args to json: {json.dumps(args, indent=4)}")


# # To Configure AWS Cloudwatch Logging

# In[ ]:


log_utils.create_cloud_watch_log_group()


# # Business Logic

# In[ ]:


def read_user_data_csv():
    global user_data_df
    csv_file_path = "./glue_job/user_data.csv"
    user_data_df = spark.read.csv(csv_file_path, header=True, inferSchema=True)
    logger.info(f"CSV file successfully read from path: {csv_file_path}")
    user_data_df.show()


log_operation("Reading User Data CSV", read_user_data_csv)


# In[ ]:


def filter_users_older_than_30():
    global filtered_user_data_df
    filtered_user_data_df = user_data_df.filter(user_data_df["age"] > 30)
    logger.info("Users older than 30 have been selected.")
    filtered_user_data_df.show()


log_operation("Filtering Users Older Than 30", filter_users_older_than_30)


# In[ ]:


def select_name_and_city_columns():
    global selected_user_data_df
    selected_user_data_df = filtered_user_data_df.select("name", "city")
    logger.info("'name' and 'city' columns have been selected.")
    selected_user_data_df.show()


log_operation("Selecting Name and City Columns", select_name_and_city_columns)


# In[ ]:


# Stop the SparkSession
job.commit()
spark.stop()

