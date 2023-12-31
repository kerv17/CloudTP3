# Use an official Ubuntu runtime as a parent imagelatest
FROM python:slim

WORKDIR /app

COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt


COPY gatekeeper.py proxy.py

EXPOSE 5000

CMD ["python3", "proxy.py"]