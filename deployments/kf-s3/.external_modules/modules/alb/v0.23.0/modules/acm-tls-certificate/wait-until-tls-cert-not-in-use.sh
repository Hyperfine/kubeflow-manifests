#!/usr/bin/env bash

set -e

if [[ "$#" -ne 1 ]]; then
  echo "ERROR: invalid number of arguments."
  echo "Usage: wait-until-tls-cert-not-in-use.sh CERT_ARN"
  exit 1
fi

readonly cert_arn="$1"

# Cert ARN should be of the format:
#
# arn:aws:acm:<REGION>:<ACCOUNT_ID>:certificate/<CERT_ID>
#
# Here we split the ARN on : and read out the region
IFS=':' read -ra arn_parts <<< "$cert_arn"
if [[ "${#arn_parts[@]}" -lt 4 ]]; then
  echo "ERROR: invalid certificate arn: $cert_arn"
  exit 1
fi
readonly cert_region="${arn_parts[3]}"

readonly max_retries=90
readonly time_between_retries_sec=30

for (( retries=0; retries<"$max_retries"; retries++ )); do
  in_use_by=$(aws acm describe-certificate \
    --region "$cert_region" \
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
