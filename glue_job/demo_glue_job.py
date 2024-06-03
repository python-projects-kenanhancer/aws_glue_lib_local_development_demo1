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

# In[3]:


import sys
from datetime import datetime


stage = "dev"
current_time = datetime.now()

sys.argv = [
    "demo_glue_job.py",  # sys.argv[0], script name
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
    "--debugging",
    "True",
    "--stage",
    stage,
    "--log_group_name",
    f"/aws-glue/jobs/demo_glue_job_{stage}",
    "--total_records",
    "1000",
    "--s3_file_path",
    "test",
]


# # Initialize AWS Glue Context

# In[4]:


import sys
import json
import logging

from glue_utils import argv_to_dict, log_operation
from log_utils import LogUtils

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
        "debugging",
        "log_group_name",
        "total_records",
        "stage",
    ],
)

log_utils = LogUtils(
    log_group_name=args["log_group_name"],
    log_stream_name=args["JOB_RUN_ID"],
    job_name=args["job"],
    execution_arn=args["execution_arn"],
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


print("sys.argv to dictionary")
print("**********************")
print(json.dumps(obj=sys.argv, indent=4))

args = argv_to_dict(argv=sys.argv)

args_json = json.dumps(args, indent=4)

print("args to dictionary")
print("**********************")
print(args_json)


# # To Configure AWS Cloudwatch Logging

# In[ ]:


log_utils.create_cloud_watch_log_group()


# # Business Logic

# In[5]:


try:
    logger.info(f"Beginning the job...")

    data = [("John", 28), ("Anna", 23), ("Mike", 35), ("Sara", 29)]

    # Create DataFrame from data
    columns = ["Name", "Age"]
    
    df = spark.createDataFrame(data, columns)

    # Show DataFrame
    df.show()

    # Select specific columns
    df.select("Name").show()

    # Filter rows based on conditions
    df.filter(df["Age"] > 25).show()

    # Group by a column and aggregate data
    df.groupBy("Age").count().show()

    logger.info("Ending the job...")
except Exception as e:
    logger.error(f"Error encountered during the job: {str(e)}", exc_info=True)
finally:
    job.commit()


# In[ ]:


# Stop the SparkSession
spark.stop()

