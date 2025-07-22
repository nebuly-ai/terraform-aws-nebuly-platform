# Changelog

# v0.11.0

- ClickHouse backups S3 bucket

# v0.10.0

- Google SSO
- ClickHouse

# v0.9.0

- Update generated `values.yaml` for Nebuly Platform Helm chart to version 1.27.0
- Remove NVIDIA T4 Node Pool (not needed anymore from Nebuly version 1.27.0)
- Add Kubernetes and RDS versions validation

# v0.8.0

- Add optional EKS prefix delegation (variable `eks_enable_prefix_delegation`)
- Update default Kubernetes version used in examples to 1.31

# v0.7.0

- New Helm templates

# v0.6.2

- Default resource limits for lion linguist service

# v0.6.1

- Use gpt3-csi as default storage class

# v0.6.0

- Use gp3 for EBS volumes of EKS nodes.
- Encrypt EBS volumes of EKS nodes.

# v0.5.1

### Minor fixes

- Missing ClusterIssuer in Helm values default configuration.

## v0.5.0

### Features

- Okta SSO integration

## v0.4.4

### Fixes

- Run Actions Processsing job on multiple GPUs.

## v0.4.3

### Fixes

- Fix missing `awsRegion` param in generated `values-bootstrap.yaml` file.

## v0.4.0

### Features

- Automatic generation of `values.yaml` for the installation of [Nebuly Platform](https://github.com/nebuly-ai/helm-charts/tree/main/nebuly-platform) Helm chart.
- Automatic generation of `values-bootsrap.yaml` for the installation of [Bootstrap AWS](https://github.com/nebuly-ai/helm-charts/tree/main/bootstrap-aws) Helm chart.
- Automatic generation of the Kubernetes Secret Provider Class manifest.

### Breaking Changes

New required variables:

- `k8s_image_pull_secret_name`: The name of the Kubernetes Image Pull Secret to use.
  This value will be used to auto-generate the values.yaml file for installing the Nebuly Platform Helm chart.
- `nebuly_credentials`: The credentials provided by Nebuly are required for activating your platform installation.
  If you haven't received your credentials or have lost them, please contact support@nebuly.ai.
- `platform_domain`: The domain on which the deployed Nebuly platform is made accessible.
- `openai_endpoint`: The endpoint of the OpenAI API.
- `openai_gpt4_deployment_name`: The name of the deployment to use for the GPT-4 model.
