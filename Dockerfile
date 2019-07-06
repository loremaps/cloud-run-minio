FROM minio/minio:RELEASE.2019-06-19T18-24-42Z

EXPOSE 8080

CMD ["minio", "gateway", "gcs", "--address=:8080", "PROJECT_ID"]