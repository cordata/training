#!/bin/bash
#done in bash because ansible didnt seem to have a way to attach a bucket policy

BUCKET_NAME=training.cordatahealth.com

read -d '' BUCKET_POLICY << EOF
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "AddPerm",
			"Effect": "Allow",
			"Principal": "*",
			"Action": "s3:GetObject",
			"Resource": "arn:aws:s3:::${BUCKET_NAME}/*"
		}
	]
}
EOF

#setup checks
  #does the `aws` command exist?
  #do we have AWS Environment variables set?

#create/check for the ${BUCKET_NAME}
EXISTS=`aws s3 ls s3://${BUCKET_NAME}`

if [ -z "$EXISTS" ]; then
  echo "creating the ${BUCKET_NAME} bucket"
  aws s3 mb s3://${BUCKET_NAME} --region us-west1
else
  echo bucket ${BUCKET_NAME} already exists
fi

#do this regardless of whether we created it this time
aws s3 website s3://${BUCKET_NAME} --index-document index.html
aws s3api put-bucket-policy --bucket ${BUCKET_NAME} --policy "${BUCKET_POLICY}"

if [ $? -eq 0 ]; then
  #build project
  bundle install
  rm -rf build
  bundle exec middleman build
  MIDDLEMAN_SUCCESS=$?

  #copy contents of build dir to S3
  if [ $MIDDLEMAN_SUCCESS -eq 0 ]; then
    aws s3 cp build s3://${BUCKET_NAME}/ --recursive
  else
    echo "Stopping. Middleman did not build successfully"
  fi
fi
