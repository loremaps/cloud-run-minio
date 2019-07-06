# Minio + Google Cloud Run

This repository shows how to run [Minio](https://min.io/) as gateway to Google Cloud Storage and
deploy it to [Google Cloud Run](https://cloud.google.com/run).

## Prerequisites:

- Google Cloud SDK (`gcloud`): https://cloud.google.com/sdk
- Enable Cloud Run API: https://console.cloud.google.com/marketplace/details/google-cloud-platform/cloud-run
- Enable Container Registry: https://console.cloud.google.com/flows/enableapi?apiid=containerregistry.googleapis.com

## Step 1: Create service account

```sh
PROJECT_ID="$(gcloud config get-value project -q)"
```

```sh
SVCACCT_NAME=minio-sa
```

Create a service account:

```sh
gcloud iam service-accounts create "${SVCACCT_NAME?}"
```

Find the email address of this account:

```sh
SVCACCT_EMAIL="$(gcloud iam service-accounts list \
  --filter="name:${SVCACCT_NAME?}@"  \
  --format=value\(email\))"
```

## Step 2: Assign permissions to the service account

We will grant to the service account **Storage Admin:** role, so it can access the Google Cloud Storage.

```sh
gcloud projects add-iam-policy-binding "${PROJECT_ID?}" \
   --member="serviceAccount:${SVCACCT_EMAIL?}" \
   --role="roles/storage.admin"
```

## Step 3: Upload minio image

Check the Dockerfile and update it with your settings.

```sh
docker build -t gcr.io/"${PROJECT_ID?}"/minio .
```

```sh
docker push gcr.io/"${PROJECT_ID?}"/minio
```

> Note: Your registry name may be something like "eu.gcr.io" if your project location is Europe. There are [four options](https://cloud.google.com/container-registry/docs/pushing-and-pulling).

## Step 4: Deploy to Cloud Run

We will now deploy our container to Google Cloud Run:

```sh
gcloud beta run deploy my-cloud-run-minio \
    --platform managed \
    --region us-central1 \
    --service-account "${SVCACCT_EMAIL?}" \
    --image gcr.io/"${PROJECT_ID?}"/minio \
    --memory 128Mi \
    --set-env-vars MINIO_ACCESS_KEY=minio \
    --set-env-vars MINIO_SECRET_KEY=minio123 \
    --allow-unauthenticated
```

> Note: Currently Cloud Run is available only in us-central1 region.

## Optinal Step: Specify storage class for your bucket

You can specify the bucket [storage class](https://cloud.google.com/storage/docs/storage-classes) of your bucket like this:

```sh
gsutil mb -p "${PROJECT_ID?}" -l us-central1 -c nearline  gs://some-bucket
```

# Clean up

Delete the service account you created:

```sh
gcloud iam service-accounts delete "${SVCACCT_EMAIL?}"
```

Delete the Cloud Run application you deployed:

```sh
gcloud beta run services delete my-cloud-run-minio \
    --platform managed \
    --region us-central1
```

---

Please provide your feedback, recommendations or improvements :bow:
