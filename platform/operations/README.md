[![Build Status](https://ci.apps.example.com/buildStatus/icon?job=ExampleOrg+Merge%2fps-tag-ops%2fmaster)](https://ci.apps.example.com/job/ExampleOrg%20Merge/job/ps-tag-ops/job/master/)
# ps-tag-ops
***
TAG infrastructure source code

## Repo overview
*** 

[docker](docker/README.md)
: houses our dockerfiles

[scripts](scripts/README.md)
: houses bash, and jenkins files.

[terraform](terraform/README.md)
: houses our IaC configuration, one root module main.tf per env/region
: these source the resource modules at init
