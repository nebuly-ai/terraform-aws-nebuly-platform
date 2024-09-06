# Changelog

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
