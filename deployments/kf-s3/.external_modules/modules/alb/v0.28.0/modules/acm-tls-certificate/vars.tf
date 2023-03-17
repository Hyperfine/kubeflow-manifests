# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED MODULE PARAMETERS
# These variables must be passed in by the operator.
# ---------------------------------------------------------------------------------------------------------------------

# AWS Terminology Explained:
# - Amazon Certificate Manager (ACM): A fully managed certificate authority that allows you to easily 
#                                     provision, manage and deploy public and private SSL/TLS certificates
#     

variable "acm_tls_certificates" {
  # Ideally, we would use a more strict type here but since we want to support required and optional values, and since
  # Terraform's type system only supports maps that have the same type for all values, we have to use the less useful
  # `any` type.

  type = any

  # Each key for each entry in the map is the fully qualified domain name (FQDN) of the certificate you want to issue
  # e.g: example.com 
  # 
  # Each entry in the map supports the following attributes: 
  #
  # OPTIONAL (defaults to value of corresponding module input): 
  # - subject_alternative_names              [list(string)] : A list of subject alternative names to include  
  #                                                           in the certificate, e.g: ["mail.example.com", "smtp.example.com"]
  # - tags                                   [map(string)]  : A map of tags to apply to the ACM certificate to be created. In this map
  #                                                           variable, the key is the tag name and the value is the tag value. Note
  #                                                           that this map is merged with var.global_tags, and can be used to override
  #                                                           tags specified in that variable.
  # 
  #                                                           N.B: there is a special tag called run_destroy_check. Its usage is demonstrated in the 
  #                                                           acm_tls_certificates example input below. If you set this tag to true, a destroy provisioner will run a bash script 
  #                                                           called wait-until-tls-cert-not-in-use.sh that polls and ensures a given certificate is no longer in use 
  #                                                           by any other AWS resources so that it can be cleanly destroyed by Terraform without error. 
  #
  #                                                           Certain AWS resources such as application load balancers 
  #                                                           and API Gateways can take a long time to be destroyed, and will prevent any certificates attached
  #                                                           to them from being destroyed. If you are unsure of what to do and are not concerned about possibly longer destroy 
  #                                                           times, then set this tag to true on all of your certificates, which will reduce your likelihood of 
  #                                                           encountering errors at destroy time
  #
  # - create_verification_record             [bool]         : When set to true, one Route 53 DNS CNAME record will be created for each of 
  #                                                           the union of the certificate domain name AND any subject alternative names you've added
  #                                                           e.g: if your certificate is issued for example.com and your SANs are mail.example.com
  #                                                           and admin.example.com, then 3 CNAME records will be created. You usually want to set this 
  #                                                           to true if you want your certificate to be automatically verified for you and you don't have 
  #                                                           any restrictions that prevent you from using Route 53 as your DNS provider for this purpose. 
  # - verify_certificate                     [bool]         : When set to true, a certificate verification action will be initiated against any records created 
  #                                                           in Route 53. If you want your certificate verified automatically, set BOTH create_verification_record
  #                                                           and verify_certificate to true in your given certificate entry in the acm_tls_certificates map
  #
  # - hosted_zone_id                         [string]       : The ID of the Route53 public hosted zone that the certificate's validation DNS records should be written to. If not 
  #                                                           supplied, the module will attempt to look up the ID of the zone by name at runtime  

  # Example: 
  #  acm_tls_certificates = {
  #    "mail.example.com" = {
  #      subject_alternative_names = ["mailme.example.com"]
  #      tags = {
  #        Environment       = "stage"
  #        run_destroy_check = true
  #      }
  #      create_verification_record = true
  #      verify_certificate         = true
  #      hosted_zone_id = 12345536646
  #    }
  #    "smtp.example.com" = {
  #      subject_alternative_names = ["smtps.example.com"]
  #      tags = {
  #        Environment       = "stage"
  #        run_destroy_check = true
  #      }
  #      create_verification_record = false
  #      verify_certificate         = true
  #     }
  #    "spare.example.com" = {
  #      subject_alternative_names = ["placeholder.example.com"]
  #      tags = {
  #        Environment       = "stage"
  #        run_destroy_check = true
  #      }
  #      create_verification_record = true
  #      verify_certificate         = true
  #     }
  #  } 
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults. 
#
# Note that those prefixed by _default may be overridden in your input on a per-certificate basis
# ---------------------------------------------------------------------------------------------------------------------

variable "global_tags" {
  description = "Global tags to apply to all ACM certificates issued via this module. These global tags will be merged with individual tags specified on each certificate input."
  type        = map(string)
  default     = {}
}

variable "default_verify_certificate" {
  description = "Whether or not to attempt to verify the issued certificate via DNS entries automatically created via Route 53 records. You may want to set this to false on your certificate inputs if you are not using Route 53 as your DNS provider."
  type        = bool
  default     = true
}

variable "default_create_verification_record" {
  description = "Whether or not to create a Route 53 DNS record for use in validating the issued certificate. Can be overridden on a per-certificate basis in the acm_tls_certificates input. You may want to set this to false if you are not using Route 53 as your DNS provider."
  type        = bool
  default     = true
}

variable "domain_hosted_zone_ids" {
  description = "Map of domains to hosted zone IDs that can be used in place of looking up with a data source. This is useful to avoid limitations of Terraform that prevent you from passing in dynamic Hosted Zone IDs in the acm_tls_certificates map due to for_each and count."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE DEPENDENCIES
# Workaround Terraform limitation where there is no module depends_on.
# See https://github.com/hashicorp/terraform/issues/1178 for more details.
# This can be used to make sure the module resources are created after other bootstrapping resources have been created.
# For example, in AWS, when provisioning a wildcard ACM certificate for a public zone, you need to create several 
# verification DNS records - but they must be created in the public zone itself. In this use case, you can pass the public 
# zones as a dependency into this module:
# dependencies = flatten([values(aws_route53_zone.public_zones).*.name_servers])
# ---------------------------------------------------------------------------------------------------------------------

variable "dependencies" {
  description = "Create a dependency between the resources in this module to the interpolated values in this list (and thus the source resources). In other words, the resources in this module will now depend on the resources backing the values in this list such that those resources need to be created before the resources in this module, and the resources in this module need to be destroyed before the resources in the list."
  type        = list(string)
  default     = []
}
