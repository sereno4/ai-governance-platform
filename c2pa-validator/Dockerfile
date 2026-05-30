FROM python:3.11-slim
RUN pip install boto3 --no-cache-dir
COPY --from=gcr.io/projectsigstore/cosign:v3.0.6 /ko-app/cosign /usr/local/bin/cosign
COPY validate.py /validate.py
CMD ["python", "/validate.py"]
