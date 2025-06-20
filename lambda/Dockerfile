

FROM public.ecr.aws/lambda/python:3.11

# Set working directory
WORKDIR /var/task

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install -r requirements.txt --target .

# Copy the lambda handler code
COPY handler.py .

# Set the Lambda handler
CMD ["handler.main"]

# do the dependency sanity check
RUN python -c "import opencv_python_headless, deepface, numpy, boto3; print('Dependencies loaded successfully')"