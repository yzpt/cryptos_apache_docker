
# =========== upload images to gcloud artifact registry ======================================
gcloud auth login

gcloud projects list
PROJECT_ID="cryptos-gcp"
gcloud config set project $PROJECT_ID

gcloud iam service-accounts list
SERVICE_ACCOUNT_EMAIL="SA-vlille@zapart-data-vlille.iam.gserviceaccount.com"

# enable Artifact Registry API
gcloud services enable artifactregistry.googleapis.com

# Set Artifact Registry administrator permissions for the service account
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" --role="roles/artifactregistry.admin"


ARTIFACT_REGISTRY_REPO_NAME="cryptos-repo"
ARTIFACT_REGISTRY_LOCATION="europe-west1"
# Create a repository on Artifact Registry
gcloud artifacts repositories create $ARTIFACT_REGISTRY_REPO_NAME --repository-format=docker --location=$ARTIFACT_REGISTRY_LOCATION --description="images for streaming clusters"

# auth config for docker
gcloud auth configure-docker $ARTIFACT_REGISTRY_LOCATION-docker.pkg.dev --quiet

docker images


# === Broker image =================================================================================================
CONTAINER_NAME="kafka-broker"
IMAGE="confluentinc/cp-server"
TAG="latest"
# docker cli modify the tag to match the registry
docker tag $IMAGE:$TAG $ARTIFACT_REGISTRY_LOCATION-docker.pkg.dev/$PROJECT_ID/$ARTIFACT_REGISTRY_REPO_NAME/$IMAGE:$TAG
docker push $ARTIFACT_REGISTRY_LOCATION-docker.pkg.dev/$PROJECT_ID/$ARTIFACT_REGISTRY_REPO_NAME/$IMAGE:$TAG

# === zookeeper image ===============================================================================================
CONTAINER_NAME="zookeeper"
IMAGE="confluentinc/cp-zookeeper"
TAG="latest"
# docker cli modify the tag to match the registry
docker tag $IMAGE:$TAG $ARTIFACT_REGISTRY_LOCATION-docker.pkg.dev/$PROJECT_ID/$ARTIFACT_REGISTRY_REPO_NAME/$IMAGE:$TAG
docker push $ARTIFACT_REGISTRY_LOCATION-docker.pkg.dev/$PROJECT_ID/$ARTIFACT_REGISTRY_REPO_NAME/$IMAGE:$TAG

# === schema-registry image ===============================================================================================
CONTAINER_NAME="schema-registry"
IMAGE="confluentinc/cp-schema-registry"
TAG="latest"
# docker cli modify the tag to match the registry
docker tag $IMAGE:$TAG $ARTIFACT_REGISTRY_LOCATION-docker.pkg.dev/$PROJECT_ID/$ARTIFACT_REGISTRY_REPO_NAME/$IMAGE:$TAG
docker push $ARTIFACT_REGISTRY_LOCATION-docker.pkg.dev/$PROJECT_ID/$ARTIFACT_REGISTRY_REPO_NAME/$IMAGE:$TAG

# === control-center image ===============================================================================================
CONTAINER_NAME="enterprise-control-center"
IMAGE="confluentinc/cp-enterprise-control-center"
TAG="latest"
# docker cli modify the tag to match the registry
docker tag $IMAGE:$TAG $ARTIFACT_REGISTRY_LOCATION-docker.pkg.dev/$PROJECT_ID/$ARTIFACT_REGISTRY_REPO_NAME/$IMAGE:$TAG
docker push $ARTIFACT_REGISTRY_LOCATION-docker.pkg.dev/$PROJECT_ID/$ARTIFACT_REGISTRY_REPO_NAME/$IMAGE:$TAG

# === apache/ariflow image ===============================================================================================
CONTAINER_NAME="airflow"
IMAGE="apache/airflow"
TAG="2.7.2-python3.10"
# docker cli modify the tag to match the registry
docker tag $IMAGE:$TAG $ARTIFACT_REGISTRY_LOCATION-docker.pkg.dev/$PROJECT_ID/$ARTIFACT_REGISTRY_REPO_NAME/$IMAGE:$TAG
docker push $ARTIFACT_REGISTRY_LOCATION-docker.pkg.dev/$PROJECT_ID/$ARTIFACT_REGISTRY_REPO_NAME/$IMAGE:$TAG

# === postgres image ===============================================================================================
CONTAINER_NAME="postgres"
IMAGE="postgres"
TAG="14.0"
# docker cli modify the tag to match the registry
docker tag $IMAGE:$TAG $ARTIFACT_REGISTRY_LOCATION-docker.pkg.dev/$PROJECT_ID/$ARTIFACT_REGISTRY_REPO_NAME/$IMAGE:$TAG
docker push $ARTIFACT_REGISTRY_LOCATION-docker.pkg.dev/$PROJECT_ID/$ARTIFACT_REGISTRY_REPO_NAME/$IMAGE:$TAG

# === spark image ===============================================================================================
CONTAINER_NAME="spark"
IMAGE="bitnami/spark"
TAG="latest"
# docker cli modify the tag to match the registry
docker tag $IMAGE:$TAG $ARTIFACT_REGISTRY_LOCATION-docker.pkg.dev/$PROJECT_ID/$ARTIFACT_REGISTRY_REPO_NAME/$IMAGE:$TAG
docker push $ARTIFACT_REGISTRY_LOCATION-docker.pkg.dev/$PROJECT_ID/$ARTIFACT_REGISTRY_REPO_NAME/$IMAGE:$TAG

# === postgresql image ===============================================================================================
CONTAINER_NAME="postgresql"
IMAGE="bitnami/postgresql"
TAG="latest"
# docker cli modify the tag to match the registry
docker tag $IMAGE:$TAG $ARTIFACT_REGISTRY_LOCATION-docker.pkg.dev/$PROJECT_ID/$ARTIFACT_REGISTRY_REPO_NAME/$IMAGE:$TAG
docker push $ARTIFACT_REGISTRY_LOCATION-docker.pkg.dev/$PROJECT_ID/$ARTIFACT_REGISTRY_REPO_NAME/$IMAGE:$TAG

