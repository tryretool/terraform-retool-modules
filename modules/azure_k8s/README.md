# Azure Kubernetes with Retool Helm
This module deploys a kubernetes cluster on Azure with two Postgresql Flexible servers (Retool backend and Temporal).

## Usage

1. Directly use the module in your existing Terraform configuration and provide the required variables  
```
module "retool_k8s" {
  source               = "git@github.com:tryretool/retool-terraform.git//modules/azure_k8s"
  resource_group_name  = "<existing-resource-group>"
  subnet_name          = "<existing-subnet-name>"
  virtual_network_name = "<existing-vnet-name>"
}

output "cluster_name" {
    value = module.retool_k8s.cluster_name
}

output "psql_fqdn" {
  value = module.retool_k8s.psql_fqdn
}

output "psql_password" {
  value = module.retool_k8s.psql_password
  sensitive = true
}

output "psql_user" {
  value = module.retool_k8s.psql_user
}

output "temporal_fqdn" {
  value = module.retool_k8s.temporal_fqdn
}

output "temporal_password" {
  value = module.retool_k8s.temporal_password
  sensitive = true
}

output "temporal_user" {
  value = module.retool_k8s.temporal_user
}
```  
2. Populate variables needed for the module.  The ones listed above are required, other optional variables are detailed in the TF Doc section below.  
3. Run `terraform init` to install all requirements for the module.  
4. Run `terraform plan` to view all planned changes to your account.  
5. Run `terraform apply` to apply all the changes
6. Make note of the outputs, these will be used for deploying Retool.
    1. Sensitive outputs (like the passwords) can be viewed with: `terraform output -json`
7. To deploy Retool, follow the instructions listed here: https://docs.retool.com/self-hosted/quickstarts/kubernetes/helm?temporal=local
    1. Follow steps 2 & 3 under "Additonal steps -> Externalize database"  
    2. `Values.config.postgres.db` should be set to `retool`  
    3. `Values.config.postgres.ssl_enabled` should be set to `true`
    4. `Values.nodeSelector` should be set to `node.kubernetes.io/name: "retool"`.  This ensures the pods are launched on the nodes created by the module.
    5. `Values.ingress.hosts` should be set to your desired dns entry.
    6. `Values.retool-temporal-services-helm.server.config.persistence.default/visibility.tls.enabled` set to `true`

## SSL
To make this Retool installation externally available and generate an SSL cert:  
1. Add the nginx and cert-manager helm repos:  
`helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx`  
`helm repo add jetstack https://charts.jetstack.io`  
2. Install nginx ingress controller:  
`helm install ingress-nginx ingress-nginx/ingress-nginx   --create-namespace   --namespace ingress-nginx    --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz`
3. Install cert-manager:  
`helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.11.0 --set installCRDs=true --set ingressShim.defaultIssuerName=letsencrypt-prod --set ingressShim.defaultIssuerKind=ClusterIssuer --set ingressShim.defaultIssuerGroup=cert-manager.io`
4. Create a cluster issuer using the following file:  
    ```
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
    name: letsencrypt-prod
    spec:
    acme:
        server: https://acme-v02.api.letsencrypt.org/directory
        email: example@example.com
        privateKeySecretRef:
        name: letsencrypt-prod
        solvers:
        - http01:
            ingress:
                class: nginx
    ```  
    `kubectl apply -f production-issuer.yml`  
5. Update the ingress section of values.yaml to be similar to this:  
    ```
    enabled: true
    # For k8s 1.18+
    ingressClassName: nginx
    labels: {}
    annotations: {}
        kubernetes.io/tls-acme: "true"
        certmanager.io/cluster-issuer: letsencrypt-prod
    hosts:
    - host: retool.example.com
        paths:
        - path: /
    tls:
    - secretName: letsencrypt-prod
        hosts:
        - retool.example.com
    servicePort: service-port
    pathType: ImplementationSpecific
    ```  
6. Apply the changes:  
`helm upgrade retool retool/retool -f values.yaml`





# TF Doc

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 3.74 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 3.74 |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_kubernetes_cluster.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster) | resource |
| [azurerm_kubernetes_cluster_node_pool.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster_node_pool) | resource |
| [azurerm_log_analytics_workspace.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace) | resource |
| [azurerm_postgresql_flexible_server.temporal](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server) | resource |
| [azurerm_postgresql_flexible_server.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server) | resource |
| [azurerm_postgresql_flexible_server_configuration.temporal](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_configuration) | resource |
| [azurerm_postgresql_flexible_server_configuration.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_configuration) | resource |
| [azurerm_postgresql_flexible_server_database.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_database) | resource |
| [azurerm_private_dns_zone.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone_virtual_network_link.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_role_assignment.k8s_nc_to_rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_subnet.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [random_password.psql_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_password.temporal_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [azurerm_resource_group.selected](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |
| [azurerm_subnet.selected](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subnet) | data source |
| [azurerm_virtual_network.selected](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_network) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_db_instance_size"></a> [db\_instance\_size](#input\_db\_instance\_size) | Instance size for external Azure Postgres server | `string` | `"GP_Standard_D4s_v3"` | no |
| <a name="input_default_node_count"></a> [default\_node\_count](#input\_default\_node\_count) | Instance count for default node pool | `string` | `"1"` | no |
| <a name="input_default_node_size"></a> [default\_node\_size](#input\_default\_node\_size) | Instance size for default node pool | `string` | `"Standard_D2_v4"` | no |
| <a name="input_k8s_dns_service_ip"></a> [k8s\_dns\_service\_ip](#input\_k8s\_dns\_service\_ip) | IP for kube-dns within service range | `string` | `"10.1.1.1"` | no |
| <a name="input_k8s_max_node_count"></a> [k8s\_max\_node\_count](#input\_k8s\_max\_node\_count) | Max number of nodes that can be autoscaled to | `number` | `3` | no |
| <a name="input_k8s_node_size"></a> [k8s\_node\_size](#input\_k8s\_node\_size) | VM size for retool node pool | `string` | `"Standard_D8_v4"` | no |
| <a name="input_k8s_service_cidr"></a> [k8s\_service\_cidr](#input\_k8s\_service\_cidr) | CIDR block for k8s service | `string` | `"10.1.0.0/16"` | no |
| <a name="input_k8s_version"></a> [k8s\_version](#input\_k8s\_version) | Kubernetes version to launch | `string` | `"1.26.6"` | no |
| <a name="input_psql_db_name"></a> [psql\_db\_name](#input\_psql\_db\_name) | Name for retool postgres database | `string` | `"retool"` | no |
| <a name="input_psql_subnet_cidr"></a> [psql\_subnet\_cidr](#input\_psql\_subnet\_cidr) | CIDR block for database subnet | `list(string)` | <pre>[<br>  "10.0.2.0/24"<br>]</pre> | no |
| <a name="input_psql_user"></a> [psql\_user](#input\_psql\_user) | Admin username for postgres database | `string` | `"retool"` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Existing resource group to create resources in | `string` | n/a | yes |
| <a name="input_ssh_key_path"></a> [ssh\_key\_path](#input\_ssh\_key\_path) | Path to SSH key for connection to VM | `string` | `"~/.ssh/id_rsa.pub"` | no |
| <a name="input_subnet_name"></a> [subnet\_name](#input\_subnet\_name) | Existing subnet to create k8s node pool in | `string` | n/a | yes |
| <a name="input_temporal_db_name"></a> [temporal\_db\_name](#input\_temporal\_db\_name) | Database name for temporal db | `string` | `"retool-temporal"` | no |
| <a name="input_temporal_user"></a> [temporal\_user](#input\_temporal\_user) | Admin username for temporal postgres database | `string` | `"retool"` | no |
| <a name="input_virtual_network_name"></a> [virtual\_network\_name](#input\_virtual\_network\_name) | Existing vnet to create resources in | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Retool k8s cluster name |
| <a name="output_psql_fqdn"></a> [psql\_fqdn](#output\_psql\_fqdn) | Retool psql flex server fqdn |
| <a name="output_psql_password"></a> [psql\_password](#output\_psql\_password) | Retool psql password |
| <a name="output_psql_user"></a> [psql\_user](#output\_psql\_user) | Retool psql user |
| <a name="output_temporal_fqdn"></a> [temporal\_fqdn](#output\_temporal\_fqdn) | Retool temporal psql flex server fqdn |
| <a name="output_temporal_password"></a> [temporal\_password](#output\_temporal\_password) | Temporal psql password |
| <a name="output_temporal_user"></a> [temporal\_user](#output\_temporal\_user) | Temporal psql user |
<!-- END_TF_DOCS -->