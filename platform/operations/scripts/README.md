#Scripts

##Parameter Store

####Prerequisites
1. Ensure you have OpenSSL 1.1 installed and that `openssl version` lists OpenSSL and not LibreSSL.
2. Ensure that you are authenticated with the correct AWS role to decrypt the files. Prod files require PROD_ADMIN. Subprod files require TEST_ADMIN.

To get OpenSSL installed on MacOS:
1. `brew install openssl@1.1`
2. `export PATH="/usr/local/opt/openssl@1.1/bin:$PATH"`
3. `openssl version` lists something like `OpenSSL 1.1.1d 10 Sep 2019`

Note: the above steps will only modify the current terminal session. This is probably the safest way to do this until MacOS uses OpenSSL by default (should be in 1.14 and later)

###`paramStore.sh` 
This script is called from a given /terraform/environments working directory to decrypt/encrypt the secure param store values.

`paramStore.sh (encrypt|decrypt)`

###`cryptAllEnvs.sh`
This script is called from the `scripts` directory and attempts to encrypt or decrypt every environments encrypted paramstore file for ease of use.
This will use the `paramStore.sh` file under the hood.

Usage:`cryptAllEnvs.sh (encrypt|decrypt)`
