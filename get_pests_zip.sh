#!/bin/bash

# Navigate to the directory containing the Lambda function
cd lambdas/pest/get_pests

# Create a ZIP file containing the Lambda function code
zip -r ../../../get_pests.zip .

# Navigate back to the original directory
cd ../..