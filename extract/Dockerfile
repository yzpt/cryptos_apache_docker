FROM python:3.10-slim

WORKDIR /app

COPY /extract /app

RUN pip3 install -r requirements_extract.txt

CMD ["python3", "main.py"]