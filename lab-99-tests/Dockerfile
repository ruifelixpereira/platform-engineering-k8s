FROM python:3.7

ADD /hello-app /app
RUN pip install -r requirements.txt

EXPOSE 5000
CMD ["python", "/app/main.py"]