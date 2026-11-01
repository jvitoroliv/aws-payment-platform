# AWS Secrets Manager Terraform Module

This module provides a flexible way to manage secrets in AWS Secrets Manager with support for multiple sources and configurations:
- HashiCorp Vault integration
- Random secret generation
- Direct value management
- Cross-region replication
- Automatic secret rotation

## Features

- 🔐 Multiple secret sources (Vault, random generation, direct values)
- 🔄 Secret rotation support
- 🌍 Cross-region replication
- 🎯 Selective Vault field retrieval
- 📦 Multi-value secret support
- 🔍 Automatic Vault secret discovery

## Usage

### Hybrid Approach

This module supports a hybrid approach to secret management:

1. **Auto-discovered Vault secrets**: Secrets placed in standard Vault paths are automatically discovered and synced to AWS Secrets Manager without explicit configuration.

2. **Explicitly defined secrets**: For special cases or non-Vault secrets, you can still define them explicitly in the tfvars files.

#### Auto-Discovery Path Conventions

Place your Vault secrets in the following paths to enable auto-discovery:

For example:
- `dev/kvv2` mount with secret at path `aws/my-api-key`
- `stage/kvv2` mount with secret at path `aws/database-password`
- `prod/kvv2` mount with secret at path `aws/payment-token`

These secrets will be automatically discovered and created in AWS Secrets Manager with the same name when the workflow is executed.

#### When to Use Explicit Definitions

Continue using explicit definitions in tfvars files for:
- Non-Vault secrets (random generation or direct values)
- Secrets requiring specific Vault versions
- Secrets requiring specific field selection
- Custom rotation settings
- Special replication requirements (by default, auto-discovered secrets are replicated to us-west-2)
- Custom tags or descriptions

### Usage with Environment Files

To create explicitly defined secrets, add their definitions to the appropriate environment tfvars file (e.g., `envs/dev/dev.tfvars`, `envs/prod/prod.tfvars`). The module will handle the creation based on these definitions.

## Use Cases

### 1. Vault Integration

#### Retrieve All Fields from a Vault Secret
```hcl
secrets = {
  "database-credentials" = {
    description = "Complete database credentials"
    from_vault  = true
    vault_mount = "/dev/kvv2"
    vault_path  = "database/credentials"
  }
}
```

#### Cherry-pick Specific Fields
```hcl
secrets = {
  "database-user" = {
    description  = "Database user credentials subset"
    from_vault   = true
    vault_mount  = "/dev/kvv2"
    vault_path   = "database/credentials"
    vault_fields = ["username", "password"]
  }
}
```

#### Retrieve Specific Version of a Vault Secret
```hcl
secrets = {
  "api-key-v1" = {
    description   = "API Key version 1"
    from_vault    = true
    vault_mount   = "/dev/kvv2"
    vault_path    = "api/credentials"
    vault_version = 1
  }
}
```

### 2. Random Secret Generation

```hcl
secrets = {
  "random-password" = {
    description         = "Randomly generated password"
    generate_random     = true
    random_length       = 32
    special_characters  = true
  }
}
```

### 3. Direct Value Management

#### Simple String Value
```hcl
secrets = {
  "api-timeout" = {
    description = "API timeout configuration"
    value       = "30s"
  }
}
```

#### Multi-value Secret
```hcl
secrets = {
  "api-config" = {
    description = "API configuration"
    value = {
      timeout     = "30s"
      retry_count = "3"
      base_url    = "https://api.example.com"
    }
  }
}
```

### 4. Cross-Region Replication

Enable replication to another AWS region:

```hcl
secrets = {
  "replicated-secret" = {
    description    = "Secret with replication"
    value         = "mysecret"
    enable_replica = true
    secondary_region = "us-west-2"
  }
}
```

### 5. Secret Rotation

Enable automatic rotation for supported secrets:

```hcl
secrets = {
  "rotating-secret" = {
    description         = "Secret with rotation"
    value              = "initial-value"
    rotation           = true
    rotation_lambda_arn = "arn:aws:lambda:us-east-1:999999999999:function:rotation-function"
    auto_rotation_days = 30
  }
}
```

## Notes

- Vault secrets require proper authentication configuration in the provider
- Random secret generation is handled by the random provider
- Secret rotation requires a properly configured Lambda function
- Cross-region replication may incur additional AWS costs