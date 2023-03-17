# Copy Snapshot Lambda Module

This module creates an [AWS Lambda](https://aws.amazon.com/lambda/) function that runs periodically and makes local
copies of snapshots of an [Amazon Relational Database (RDS)](https://aws.amazon.com/rds/) database that were shared 
from some external AWS account. This allows you to make backups of your RDS snapshots in a totally separate AWS 
account.

Note that to use this module, you must have access to the Gruntwork [Continuous Delivery Infrastructure Package 
(terraform-aws-ci)](https://github.com/gruntwork-io/terraform-aws-ci). If you need access, email support@gruntwork.io.




## How do you use this module?

See the [lambda-rds-snapshot example](/examples/lambda-rds-snapshot) for sample code. 

If you are using this function to copy snapshots to another AWS account, you may also want to look at the 
[lambda-create-snapshot](/modules/lambda-create-snapshot) and 
[lambda-share-snapshot](/modules/lambda-share-snapshot) modules.



## How do you copy an encrypted snapshot?

Let's say you created an RDS  snapshot in account 111111111111 encrypted with a KMS key and shared that snapshot with 
account 222222222222. To be able to make a copy of that snapshot in account 222222222222 using this module, you must:

1. Give account 222222222222 access to the KMS key in account 111111111111, including the `kms:CreateGrant` permission. 
   If you're using the [kms-master-key module](https://github.com/gruntwork-io/terraform-aws-security/blob/master/modules/kms-master-key) 
   to manage your KMS keys, then in account 111111111111, you add the ARN of account 222222222222 to the 
   `cmk_user_iam_arns` variable:
   
    ```hcl
    # In account 111111111111
 
    module "kms_master_key" {
      source = "git::git@github.com:gruntwork-io/terraform-aws-security.git//modules/kms-master-key?ref=<VERSION>"

      cmk_user_iam_arns = ["`arn:aws:iam::222222222222:root`"]

      # (Other params omitted)
    }
    ```
   
1. In account 222222222222, you create another KMS key which can be used to re-encrypt the copied snapshot. You need
   to give the Lambda function in this module permissions to use that key as follows:
   
    ```hcl
    # In account 222222222222
 
    module "kms_master_key" {
      source = "git::git@github.com:gruntwork-io/terraform-aws-security.git//modules/kms-master-key?ref=<VERSION>"

      # (Other params omitted)
    }
     
    module "copy_snapshot" {
      source = "git::git@github.com:gruntwork-io/terraform-aws-data-storage.git//modules/lambda-copy-shared-snapshot?ref=<VERSION>"
      
      # Tell this copy snapshot module to use this key to encrypt the copied snapshot
      kms_key_id = "${module.kms_master_key.key_arn}"
   
      # (Other params omitted)
    }

    # Giver the copy snapshot module permissions to use the KMS key
    resource "aws_iam_role_policy" "access_kms_master_key" {
      name   = "access-kms-master-key"
      role   = "${module.copy_snapshot.lambda_iam_role_id}"
      policy = "${data.aws_iam_policy_document.access_kms_master_key.json}"
    }
    
    data "aws_iam_policy_document" "access_kms_master_key" {
      statement {
        effect = "Allow"
        actions = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        resources = ["${module.kms_master_key.key_arn}"]
      }
    
      statement {
        effect = "Allow"
        resources = ["*"]
        actions = [
          "kms:CreateGrant",
          "kms:ListGrants",
          "kms:RevokeGrant"
        ]
        condition {
          test = "Bool"
          variable = "kms:GrantIsForAWSResource"
          values = ["true"]
        }
      }
    }
    ```  




## Background info

For more info on how to backup RDS snapshots to a separate AWS account, check out the [lambda-create-snapshot module
documentation](/modules/lambda-create-snapshot).