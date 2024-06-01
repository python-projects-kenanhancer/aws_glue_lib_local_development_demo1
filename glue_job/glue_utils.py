import os


def is_running_in_aws_glue():
    # AWS Glue sets specific environment variables, you can check one of those
    # For this example, we're just checking a dummy variable. Adjust it based on your actual environment.
    return os.getenv("IS_LOCAL") is None


def argv_to_dict(argv):
    arg_dict = {}
    i = 1  # Start from 1 to skip the script name
    while i < len(argv):
        if argv[i].startswith("--"):
            key = argv[i][2:].replace(
                "-", "_"
            )  # Remove '--' prefix and replace '-' with '_'
            if i + 1 < len(argv) and not argv[i + 1].startswith("--"):
                value = argv[i + 1]
                i += 2
            else:
                value = True
                i += 1
            # Convert strings 'true'/'false' to boolean values
            if value.lower() in ["true", "false"]:
                value = value.lower() == "true"
            arg_dict[key] = value
        else:
            i += 1

    return arg_dict
