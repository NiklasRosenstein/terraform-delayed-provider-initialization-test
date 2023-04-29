
This repository tests delayed provider initialization in Terraform, attempting to create a resource, subsequently
initializing a provider from that resource and creating a resource using that new provider. This is a useful pattern
to describe infrastructure end-to-end.

## Test cases

### Kubernetes/Helm Provider (`do-kubernetes/`)

This test stands up a Kubernetes cluster on [DigitalOcean][] and subsequently deploying a Kubernetes secret and
Helm chart into the cluster using the `kubernetes` and `helm` providers.

__Run__:

    $ DIGITALOCEAN_TOKEN=... terraform apply

__Status__:

* ✅ Create
* ✅ Destroy
* ❌ Recreate cluster
    * When the cluster is recreated, the `kubernetes` resources would need to be recreated as well. However, Terraform
      is not aware that in this case, it must treat the existing resources as tainted and recreate them. And even if
      it did, it would need to understand that the resources do not even need to be destroyed.

      It cannot destroy them, because the `digitalocean_kubernetes_cluster` resource in it's plan to be recreated does
      __not__ return the credentials of the old cluster. 

      > Note: This may be an implementation detail of the DigitalOcean provider, but it means we cannot generally
      > assume that this scenario works.

<details><summary>Terraform Apply Logs after changing the default node pool size, causing the cluster to be recreated.</summary>

<pre>
> DIGITALOCEAN_TOKEN=... terraform apply 
digitalocean_kubernetes_cluster.main: Refreshing state... [id=25abff0c-ee6d-452c-95dd-db7c5cb2330a]
helm_release.ingress_nginx: Refreshing state... [id=ingress-nginx]
kubernetes_secret.test: Refreshing state... [id=default/test]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
-/+ destroy and then create replacement

Terraform planned the following actions, but then encountered a problem:

  # digitalocean_kubernetes_cluster.main must be replaced
-/+ resource "digitalocean_kubernetes_cluster" "main" {
      - auto_upgrade         = false -> null
      ~ cluster_subnet       = "10.244.0.0/16" -> (known after apply)
      ~ created_at           = "2023-04-29 12:35:47 +0000 UTC" -> (known after apply)
      ~ endpoint             = "https://25abff0c-ee6d-452c-95dd-db7c5cb2330a.k8s.ondigitalocean.com" -> (known after apply)
      ~ id                   = "25abff0c-ee6d-452c-95dd-db7c5cb2330a" -> (known after apply)
      + ipv4_address         = (known after apply)
      ~ kube_config          = (sensitive value)
        name                 = "do-kubernetes"
      ~ service_subnet       = "10.245.0.0/16" -> (known after apply)
      ~ status               = "running" -> (known after apply)
      - tags                 = [] -> null
      ~ updated_at           = "2023-04-29 12:45:31 +0000 UTC" -> (known after apply)
      ~ urn                  = "do:kubernetes:25abff0c-ee6d-452c-95dd-db7c5cb2330a" -> (known after apply)
      ~ vpc_uuid             = "c9d34c7b-7592-4d89-9ab8-317241c5aa87" -> (known after apply)
        # (5 unchanged attributes hidden)

      - maintenance_policy {
          - day        = "any" -> null
          - duration   = "4h0m0s" -> null
          - start_time = "23:00" -> null
        }

      ~ node_pool {
          ~ actual_node_count = 1 -> (known after apply)
          ~ id                = "2f9497ba-4ef2-4acc-85c2-c24c6222a4cb" -> (known after apply)
          - labels            = {} -> null
          - max_nodes         = 0 -> null
          - min_nodes         = 0 -> null
            name              = "default"
          ~ nodes             = [
              - {
                  - created_at = "2023-04-29 12:35:47 +0000 UTC"
                  - droplet_id = "352948881"
                  - id         = "ed1b2af4-78fd-4a84-94b4-eabd4a8bf66e"
                  - name       = "default-f729x"
                  - status     = "running"
                  - updated_at = "2023-04-29 12:37:57 +0000 UTC"
                },
            ] -> (known after apply)
          ~ size              = "s-2vcpu-2gb" -> "s-4vcpu-2gb" # forces replacement
          - tags              = [] -> null
            # (2 unchanged attributes hidden)
        }
    }

Plan: 1 to add, 0 to change, 1 to destroy.
╷
│ Error: Get "http://localhost/api/v1/namespaces/default/secrets/test": dial tcp [::1]:80: connect: connection refused
│ 
│   with kubernetes_secret.test,
│   on main.tf line 34, in resource "kubernetes_secret" "test":
│   34: resource "kubernetes_secret" "test" {
│ 
╵
╷
│ Error: Kubernetes cluster unreachable: invalid configuration: no configuration has been provided, try setting KUBERNETES_MASTER environment variable
│ 
│   with helm_release.ingress_nginx,
│   on main.tf line 44, in resource "helm_release" "ingress_nginx":
│   44: resource "helm_release" "ingress_nginx" {
│ 
╵
</pre>
</details>

### Refaktory MinIO Provider (`vultr-refaktory-minio/`)

This test stands up a [Vultr][] storage account and subsequently creating a storage bucket using the `refaktory/minio`
provider.

__Run__:

    $ VULTR_API_KEY=... terraform apply

__Status__:

* ❌ Create
    * The `refaktory/minio` provider does not seem to support delayed initialization. It is not possible to create a
        resource using the provider if a resource needs to be created to initialize the provider.

<details><summary>Terraform Create Logs</summary>

<pre>
> VULTR_API_KEY=... terraform apply
data.vultr_object_storage_cluster.ams: Reading...
data.vultr_object_storage_cluster.ams: Read complete after 1s

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform planned the following actions, but then encountered a problem:

  # vultr_object_storage.main will be created
  + resource "vultr_object_storage" "main" {
      + cluster_id    = 6
      + date_created  = (known after apply)
      + id            = (known after apply)
      + label         = "test-storage"
      + location      = (known after apply)
      + region        = (known after apply)
      + s3_access_key = (sensitive value)
      + s3_hostname   = (known after apply)
      + s3_secret_key = (sensitive value)
      + status        = (known after apply)
    }

Plan: 1 to add, 0 to change, 0 to destroy.
╷
│ Error: Endpoint:  does not follow ip address or domain name standards.
│ 
│   with provider["registry.terraform.io/refaktory/minio"],
│   on main.tf line 25, in provider "minio":
│   25: provider "minio" {
│ 
╵
</pre>
</details>

### aminueza MinIO Provider (`vultr-aminueza-minio/`)

Similar to the test before, this test stands up a [Vultr][] storage account and subsequently creating a storage
bucket using the `aminueza/minio` provider.

__Run__:

    $ VULTR_API_KEY=... terraform apply

__Status__

* ❌ Create
    * Same as with the `refaktory/minio` provider.

<details><summary>Terraform Apply Logs</summary>

<pre>
> VULTR_API_KEY=... terraform apply
data.vultr_object_storage_cluster.ams: Reading...
data.vultr_object_storage_cluster.ams: Read complete after 0s

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform planned the following actions, but then encountered a problem:

  # vultr_object_storage.main will be created
  + resource "vultr_object_storage" "main" {
      + cluster_id    = 6
      + date_created  = (known after apply)
      + id            = (known after apply)
      + label         = "test-storage"
      + location      = (known after apply)
      + region        = (known after apply)
      + s3_access_key = (sensitive value)
      + s3_hostname   = (known after apply)
      + s3_secret_key = (sensitive value)
      + status        = (known after apply)
    }

Plan: 1 to add, 0 to change, 0 to destroy.
╷
│ Error: [FATAL] client creation failed (client): Endpoint:  does not follow ip address or domain name standards.
│ 
│   with provider["registry.terraform.io/aminueza/minio"],
│   on main.tf line 25, in provider "minio":
│   25: provider "minio" {
│ 
╵
</pre>
</details>
