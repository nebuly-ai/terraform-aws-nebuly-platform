# Changelog

## v0.4.0

### Features

- Automatic generation of `values.yaml` for Helm installation.
- Automatic generation of the Kubernetes Secret Provider Class manifest.

### Breaking Changes

New required variables:

- `k8s_image_pull_secret_name`
- `nebuly_credentials`
- `platform_name`
- `openai_endpoint`
- `openai_gpt4_deployment_name`
