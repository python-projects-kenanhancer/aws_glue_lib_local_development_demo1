# aws_glue_lib_local_development_demo1
This demo shows how to use AWS Glue Python packages locally via https://docs.aws.amazon.com/glue/latest/dg/aws-glue-programming-etl-libraries.html#develop-using-etl-library

> I could run it finally :)

```
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
```

```
+----+---+
|Name|Age|
+----+---+
|John| 28|
|Anna| 23|
|Mike| 35|
|Sara| 29|
+----+---+

+----+
|Name|
+----+
|John|
|Anna|
|Mike|
|Sara|
+----+

+----+---+
|Name|Age|
+----+---+
|John| 28|
|Mike| 35|
|Sara| 29|
+----+---+

+---+-----+
|Age|count|
+---+-----+
| 28|    1|
| 23|    1|
| 35|    1|
| 29|    1|
+---+-----+


```