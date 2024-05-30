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

# In[1]:


import sys
from datetime import datetime


stage = "dev"
current_time = datetime.now()

sys.argv = [
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
    "--debugging",
    "True",
    "--stage",
    stage,
    "--log_group_name",
    f"/aws-glue/jobs/convert-csv-to-parque-glue-job-{stage}",
    "--total_records",
    "1000",
    "--s3_file_path",
    "test",
]


# # Initialize AWS Glue Context

# In[2]:


import sys
import json
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
        "execution_arn",
        "debugging",
        "log_group_name",
        "total_records",
        "stage",
    ],
)

# Initialize Glue context
glueContext = GlueContext(SparkContext.getOrCreate())
spark = glueContext.spark_session
logger = glueContext.get_logger()
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

print("sys.argv to dictionary")
print("**********************")
# args = argv_to_dict(sys.argv)

# print("args to dictionary")
# print("**********************")
# print(json.dumps(args, indent=4))


# In[3]:


try:
    # logger.info(f"Starting the Glue job with sys.argv: {sys_argv_json}")

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

    logger.info("Ending the Glue job...")

except Exception as e:

    logger.error(f"Error encountered during the Glue job: {str(e)}", exc_info=True)

finally:

    job.commit()


# In[ ]:


# Stop the SparkSession
spark.stop()

