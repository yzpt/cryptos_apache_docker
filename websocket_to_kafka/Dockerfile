# Use an official Python runtime as a parent image
FROM python:3.10-slim

WORKDIR /app

COPY . /app

# Install any needed packages specified in requirements.txt
RUN pip3 install -r requirements_websocket_to_kafka.txt

# Run your script when the container launches
CMD ["python3", "main.py"]