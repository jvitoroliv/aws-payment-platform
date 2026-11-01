## Configuration
This directory contains configuration files for the project. The configuration files are written in YAML format.

**Environment**
 - environment (string): Specifies the environment (e.g., local, staging, production). Defaults to local.

**AWS Region**
 - awsRegion (string): AWS region code (e.g., us-east-1).

**Scheduler** the scheduler that executes any task/job at an interval configured in a cron expression.
 - cron (string): the cron expression set in the scheduler.

**Processor** the job that is executed by the scheduler.
 - postPaymentMaxRetries (integer): maximum number of attempts to retry payment processing before considering it failed.
 - postPaymentTimeout (integer): timeout in seconds for the payment processing API call.
 - maxConsecutiveFailures (integer): number of consecutive processing failures after which the job stops the processing; the remaining payments will be processed by the next job.

**MongoDB** the database.
 - dbName (string): name of the MongoDB database to use.
 - username (string): username for MongoDB authentication.
 - password (string): password for MongoDB authentication. Omit or store securely.
 - uri (string): URI for connecting to the MongoDB database (e.g., mongodb://localhost:27017).
 - connectTimeout (integer): timeout in seconds for connecting to the MongoDB database.
 - clientTimeout (integer): timeout in seconds for database operations.

**Server** the server in which the API is run
 - addr (string): address and port for the application server (e.g., :8000).
 - ginMode (string): Gin framework mode (e.g., debug, release).
 - timeout (integer): server timeout in seconds for handling requests.

**Tag Core** the service responsible for processing and validating payments
 - baseURL (string): base URL of the Tag Core service. Used for communication.
 - timeout (integer): timeout in seconds for requests to the Tag Core service. Defaults to 3.
 - maxRetries (integer): maximum number of retries for requests to the Tag Core service. Defaults to 1.
 - username (string): username for Tag Core service authentication.
 - password (string): password for Tag Core service authentication. Omit or store securely.