# $action_name

$action_description

## Inputs

- **named_input**:
  - *Description*: Some input that is named.
  - *Required*: true

## Usage

```yaml
steps:
  - name: Checkout Repository
    uses: actions/checkout@v4

  - name: Run $action_name
    uses: example-org/shared-actions/$action_path@v1
    with:
      command: 'upload'
      extra_args: '--flat=true'
      source: './packages_folder/*.nupkg'
      target: 'fabric-nuget-subprod/'
```
