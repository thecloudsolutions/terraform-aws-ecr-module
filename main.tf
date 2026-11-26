module "ecr" {
  source = "git::https://github.com/thecloudsolutions/terraform-aws-ecr-component.git?ref=main"

  ecr_map = { for key, ecr in var.ecr_map :
    key =>
    merge(ecr,
      {
        repository = ecr.repository != null ? merge(ecr.repository,
          {
            encryption_configuration = ecr.repository.encryption_configuration != null ? merge(ecr.repository.encryption_configuration,
              {
                kms_key = try(ecr.repository.encryption_configuration.kms_key, null) != null ? ecr.repository.encryption_configuration.kms_key : try(ecr.repository.encryption_configuration.replica_key_custom_name, null) != null ? try(module.kms.kms_replica_external_key_arns[ecr.repository.encryption_configuration.kms_key_custom_name][ecr.repository.encryption_configuration.replica_key_custom_name], module.kms.kms_replica_key_arns[ecr.repository.encryption_configuration.kms_key_custom_name][ecr.repository.encryption_configuration.replica_key_custom_name]) : try(ecr.repository.encryption_configuration.kms_key_custom_name, null) != null ? module.kms.kms_key_arns[ecr.repository.encryption_configuration.kms_key_custom_name] : null
              }
            ) : null
          }
        ) : null

        repository_policy = ecr.repository_policy != null ? merge(ecr.repository_policy,
          { policy = try(ecr.repository_policy.policy, null) != null ? ecr.repository_policy.policy : module.iam.iam_policy_document_jsons[ecr.repository_policy.iam_custom_name][ecr.repository_policy.policy_custom_name] }
        ) : null

        registry_policy = ecr.registry_policy != null ? merge(ecr.registry_policy,
          { policy = try(ecr.registry_policy.policy, null) != null ? ecr.registry_policy.policy : module.iam.iam_policy_document_jsons[ecr.registry_policy.iam_custom_name][ecr.registry_policy.policy_custom_name] }
        ) : null

        pull_through_cache_rules = { for rule_key, rule in ecr.pull_through_cache_rules :
          rule_key => merge(rule,
            { custom_role_arn = try(rule.custom_role_arn, null) != null ? rule.custom_role_arn : try(rule.iam_role_custom_name, null) != null ? module.iam.iam_role_arns[rule.iam_role_custom_name] : null }
          )
        }

        repository_creation_templates = { for template_key, template in ecr.repository_creation_templates :
          template_key => merge(template,
            {
              custom_role_arn   = try(template.custom_role_arn, null) != null ? template.custom_role_arn : try(template.iam_role_custom_name, null) != null ? module.iam.iam_role_arns[template.iam_role_custom_name] : null
              repository_policy = try(template.repository_policy, null) != null ? template.repository_policy : try(template.repository_policy_custom_name, null) != null ? module.iam.iam_policy_document_jsons[template.iam_custom_name][template.repository_policy_custom_name] : null
              encryption_configuration = template.encryption_configuration != null ? merge(template.encryption_configuration,
                {
                  kms_key = try(template.encryption_configuration.kms_key, null) != null ? template.encryption_configuration.kms_key : try(template.encryption_configuration.replica_key_custom_name, null) != null ? try(module.kms.kms_replica_external_key_arns[template.encryption_configuration.kms_key_custom_name][template.encryption_configuration.replica_key_custom_name], module.kms.kms_replica_key_arns[template.encryption_configuration.kms_key_custom_name][template.encryption_configuration.replica_key_custom_name]) : try(template.encryption_configuration.kms_key_custom_name, null) != null ? module.kms.kms_key_arns[template.encryption_configuration.kms_key_custom_name] : null
                }
              ) : null
            }
          )
        }

        pull_time_update_exclusions = { for exclusion_key, exclusion in ecr.pull_time_update_exclusions :
          exclusion_key => merge(exclusion,
            { principal_arn = try(exclusion.principal_arn, null) != null ? exclusion.principal_arn : module.iam.iam_role_arns[exclusion.role_custom_name] }
          )
        }
      }
    )
  }

  depends_on = [module.kms, module.iam]
}

module "kms" {
  source = "git::https://github.com/thecloudsolutions/terraform-aws-kms-component.git?ref=main"

  kms_map = { for key, kms in var.kms_map :
    key => merge(kms,
      {
        key = try(kms.key, null) != null ? merge(kms.key,
          { policy = try(kms.key.policy, null) != null ? kms.key.policy : try(kms.key.policy_custom_name, null) != null ? module.iam.iam_policy_document_jsons[kms.key.iam_custom_name][kms.key.policy_custom_name] : null }
        ) : null

        external_key = try(kms.external_key, null) != null ? merge(kms.external_key,
          { policy = try(kms.external_key.policy, null) != null ? kms.external_key.policy : try(kms.external_key.policy_custom_name, null) != null ? module.iam.iam_policy_document_jsons[kms.external_key.iam_custom_name][kms.external_key.policy_custom_name] : null }
        ) : null

        grants = { for grant_key, grant in kms.grants :
          grant_key => merge(grant,
            {
              grantee_principal  = try(grant.grantee_principal, null) != null ? grant.grantee_principal : try(grant.grantee_role_custom_name, null) != null ? module.iam.iam_role_arns[grant.grantee_role_custom_name] : try(grant.grantee_user_custom_name, null) != null ? module.iam.iam_user_arns[grant.grantee_iam_custom_name][grant.grantee_user_custom_name] : try(grant.grantee_service_linked_role_custom_name, null) != null ? module.iam.iam_service_linked_role_arns[grant.grantee_iam_custom_name][grant.grantee_service_linked_role_custom_name] : null
              retiring_principal = try(grant.retiring_principal, null) != null ? grant.retiring_principal : try(grant.retiring_role_custom_name, null) != null ? module.iam.iam_role_arns[grant.retiring_role_custom_name] : try(grant.retiring_user_custom_name, null) != null ? module.iam.iam_user_arns[grant.retiring_iam_custom_name][grant.retiring_user_custom_name] : try(grant.retiring_service_linked_role_custom_name, null) != null ? module.iam.iam_service_linked_role_arns[grant.retiring_iam_custom_name][grant.retiring_service_linked_role_custom_name] : null
            }
          )
        }

        replica_keys = { for replica_key, replica in kms.replica_keys :
          replica_key => merge(replica,
            { policy = try(replica.policy, null) != null ? replica.policy : try(replica.policy_custom_name, null) != null ? module.iam.iam_policy_document_jsons[replica.iam_custom_name][replica.policy_custom_name] : null }
          )
        }

        replica_external_keys = { for replica_key, replica in kms.replica_external_keys :
          replica_key => merge(replica,
            { policy = try(replica.policy, null) != null ? replica.policy : try(replica.policy_custom_name, null) != null ? module.iam.iam_policy_document_jsons[replica.iam_custom_name][replica.policy_custom_name] : null }
          )
        }

        key_policy = try(kms.key_policy, null) != null ? merge(kms.key_policy,
          { policy = try(kms.key_policy.policy, null) != null ? kms.key_policy.policy : try(kms.key_policy.policy_custom_name, null) != null ? module.iam.iam_policy_document_jsons[kms.key_policy.iam_custom_name][kms.key_policy.policy_custom_name] : null }
        ) : null
      }
    )
  }
}

module "iam" {
  source = "git::https://github.com/thecloudsolutions/terraform-aws-iam-component.git?ref=main"

  iam_map = var.iam_map
}
