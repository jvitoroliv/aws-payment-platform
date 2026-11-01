# CPT Tags

This module handles building tag outputs as both a map and a list to accommodate standard tagging and ASGs.
The tags defined in this module are based on [this tagging document](https://drive.google.com/file/d/1BPKGmGKBzAm7ewXGR3-T5RoPpugAJKto/view?ths=true)

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| billing |  | string | n/a | yes |
| compliance |  | string | n/a | yes |
| dataclass |  | string | n/a | yes |
| drtier |  | string | n/a | yes |
| environment |  | string | n/a | yes |
| lob |  | string | n/a | yes |
| owner |  | string | n/a | yes |
| projectname |  | string | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| autoscaling\_tags |  |
| tags |  |
