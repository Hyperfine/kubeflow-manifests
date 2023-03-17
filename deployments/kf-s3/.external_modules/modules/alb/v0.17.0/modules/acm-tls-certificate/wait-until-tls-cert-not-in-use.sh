#!/usr/bin/env bash

set -e

if [[ "$#" -ne 2 ]]; then
  echo "ERROR: invalid number of arguments."
  echo "Usage: wait-until-tls-cert-not-in-use.sh REGION CERT_ARN"
  exit 1
fi

readonly aws_region="$1"
readonly cert_arn="$2"

readonly max_retries=90
readonly time_between_retries_sec=30

for (( retries=0; retries<"$max_retries"; retries++ )); do
  in_use_by=$(aws acm describe-certificate \
    --region "$aws_region" \
    --certificate-arn "$cert_arn" \
    --query 'Certificate.InUseBy')

  if [[ "$in_use_by" == '[]' ]]; then
    echo "ACM certificate $cert_arn is not used by anything. It is now safe to delete it!"
    exit
  else
    echo "ACM certificate $cert_arn is still in use, so need to wait longer before trying to delete it! Unfortunately, some resources can take a LONG time to delete (e.g., 10 - 30 minutes for API Gateway!). Will sleep for $time_between_retries_sec seconds and check again."
    echo "$in_use_by"
    sleep "$time_between_retries_sec"
  fi
done

echo "ERROR: max retries ($max_retries) exceeded while waiting for ACM certificate $cert_arn to no longer be in use."
exit 1
