

FROM public.ecr.aws/lambda/python:3.10

# Set working directory
WORKDIR /var/task

# Install OS-level dependencies
RUN yum update -y && \
    yum install -y gcc gcc-c++ make python3-devel mesa-libGL


# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install -r requirements.txt --target .

# Copy the lambda handler code
COPY handler.py .

# Set the Lambda handler
CMD ["handler.main"]

# do the dependency sanity check
RUN python -c "import cv2, deepface, numpy, boto3; print('Dependencies loaded successfully')"