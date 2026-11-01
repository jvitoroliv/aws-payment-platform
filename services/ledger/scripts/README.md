# Scripts

## Launching the Producer

A script is included to help build and launch the project using a
local docker compose set-up, `build_and_run_local.sh`.

## Generating Test Data

A script is included to help with generating test data,
`gen_data.py`. The help output is as follows and should guide you
towards its general usage:

```
$ python3 ./scripts/gen_data.py --help
Usage: Generates data for use in testing the ledger producer..

Meant to be used with mongoimport. For example:

$ python3 gen_data.py --count 20 --auths-path auths.json --ledgers-path ledgers.json
$ mongoimport -d mock-service -c authorization --jsonArray auths.json
$ mongoimport -d mock-service -c companyledger --jsonArray ledgers.json

Options:
  -h, --help            show this help message and exit
  -c COUNT, --count=COUNT
                        Number of ledger entries (and matching transactions)
                        to generate.
  --auths-path=AUTHS_PATH
                        Where to store genrated auths.
  --ledgers-path=LEDGERS_PATH
                        Where to store generated ledger entries.
```
