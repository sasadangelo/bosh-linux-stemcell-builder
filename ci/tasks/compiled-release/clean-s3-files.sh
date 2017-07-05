#!/usr/bin/env bash

source pipeline-src/ci/tasks/utils.sh

check_param AWS_ACCESS_KEY_ID
check_param AWS_SECRET_ACCESS_KEY
check_param AWS_ENDPOINT
check_param AWS_DEFAULT_REGION
check_param AWS_BUCKET

BUILD_VERSION=`cat version/version | cut -d "." -f 3`


echo "Install python and pip"
apt-get update && apt-get install -y python-pip libpython-dev

echo "Install awscli"
pip install awscli

export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
export AWS_ENDPOINT=${AWS_ENDPOINT}
export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}
export AWS_BUCKET=${AWS_BUCKET}

echo "List bucket ${AWS_BUCKET}"
aws --endpoint-url "https://${AWS_ENDPOINT}" s3 ls ${AWS_BUCKET}

echo "Remove director-state/director-state-${BUILD_VERSION}.tgz"
aws --endpoint-url "https://${AWS_ENDPOINT}" s3 rm "s3://${AWS_BUCKET}/director-state/director-state-${BUILD_VERSION}.tgz"

echo "Remove compiled-release/compiled-release-allinone-${BUILD_VERSION}.tgz"
aws --endpoint-url "https://${AWS_ENDPOINT}" s3 rm "s3://${AWS_BUCKET}/compiled-release/compiled-release-allinone-${BUILD_VERSION}.tgz"

echo "Remove compiled-deploy/compiled-deploy-${BUILD_VERSION}.yml"
aws --endpoint-url "https://${AWS_ENDPOINT}" s3 rm "s3://${AWS_BUCKET}/compiled-deploy/compiled-deploy-${BUILD_VERSION}.yml"

echo "List bucket ${AWS_BUCKET} after remove"
aws --endpoint-url "https://${AWS_ENDPOINT}" s3 ls ${AWS_BUCKET}
