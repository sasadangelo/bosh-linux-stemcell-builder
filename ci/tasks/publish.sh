#!/bin/bash

set -u

export VERSION=$( cat version/number | sed 's/\.0$//;s/\.0$//' )
stemcell=$(realpath stemcell/*.tgz)

for file in $COPY_KEYS ; do
  file="${file/\%s/$VERSION}"

  echo "$file"
  echo "$stemcell"

  checksum="$(sha1sum "${stemcell}" | awk '{print $1}')"
  echo "$file sha1=$checksum"

  # occasionally this fails for unexpected reasons; retry a few times
  for i in {1..4}; do
    aws --endpoint-url "https://${AWS_ENDPOINT}" s3 cp "s3://${CANDIDATE_BUCKET_NAME}/$file" "s3://${PUBLISHED_BUCKET_NAME}/$file" \
      && break \
      || sleep 5
  done

done

fileUrl=https://s3-api.us-geo.objectstorage.softlayer.net/${PUBLISHED_BUCKET_NAME}/${file}
echo -e "Stemcell Download URL -> ${fileUrl}"
checksum=`curl -L ${fileUrl} | sha1sum | cut -d " " -f 1`
echo -e "Sha1 hashcode -> $checksum"

echo "Done"
