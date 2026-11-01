#!/bin/bash
set -e

# Get current directory
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do SOURCE="$(readlink "$SOURCE")"; done
cwd="$(cd -P "$(dirname "$SOURCE")" && pwd)"
root="$cwd/../"
remainOnExit="on"

echo Working dir = $cwd
echo Project Root = $root

nonAwsInstance="true"
enableTokenizer=""

function usage() {
  app_name=$(basename $0)
  error_msg=$1
  if [ "x$error_msg" != "x" ]; then
    echo $error_msg 1>&2
  fi

  echo "Usage $app_name: [options...]" >&2
  echo -n >&2
  echo "  Options:" >&2
  echo "  -n (y|n) - set non aws instance, defaults y"
  echo "  -a (address) - MIP address" >&2
  echo "  -m (y|n) - start mongo, defaults n" >&2
  echo "  -x (y|n) - set remain on exit on 'on'" >&2
  echo "  -t - enable tokenization when non aws instance is set" >&2
  echo "  -h - help" >&2
  echo -n >&2

  exit 1
}

# process command line arguments
while getopts r:a:m:htx: flag; do
  case $flag in
  a)
    mipAddress="$OPTARG"
    ;;
  m)
    startMongo="$OPTARG"
    ;;
  x)
    if [ "$OPTARG" != "y" ]; then
      remainOnExit="off"
    fi
    ;;
  h)
    usage
    ;;
  t)
    enableTokenizer="-enableTokenizer"
    ;;
  ?)
    usage "Unknown option"
    ;;
  esac
done
shift $((OPTIND - 1))

if [[ -z "$startMongo" ]]; then
  echo -n "Checking if mongo is running..."
  if pgrep -x mongod >/dev/null; then
    echo "Mongod is running, won't start"
    startMongo="n"
  else
    echo "Mongod is not running, will start"
    startMongo="y"
  fi
fi

enableSimulator="false"
if [[ ! -z "$mipAddress" ]]; then
  enableSimulator="true"
fi

LOG_DIR=/tmp/logs
mkdir -p $LOG_DIR

# END Setup up env vars

echo 'Starting up stuff'

# Set up the session to make it slicker 'n' shit
tmux new-session -d -s mock-service-test-harness
tmux bind-key p respawn-pane -k

if [[ "$startMongo" == "y" ]]; then
  echo "Starting mongo"
  # Create/configure mongo/consul window
  tmux new-window -t mock-service-test-harness -n 'Mongo'
  tmux set remain-on-exit $remainOnExit
  if [[ -e ~/start_mongo.sh ]]; then
    tmux split-window -v -p 45 ~/start_mongo.sh
  else
    logpath=$root/scripts/dev_scripts/mongo_logs/mongod.log
    mkdir -p $(dirname $logpath)
    tmux split-window -v -p 45 mongod --dbpath ~/mongo --storageEngine wiredTiger --logpath $logpath --setParameter logComponentVerbosity={command:{verbosity:2}}
  fi

  tmux select-pane -t 0
  tmux split-window -v -p 90 mongo
fi

echo "Pre-building everything...speeds things up"
echo $root
cd $root && go list ./cmd/... | xargs go install

echo "Moving on"
cd $cwd

echo "Starting CorePlatform Job along with mock CorePlatform endpoint"
# Create/configure auth window
tmux new-window -t mock-service-test-harness -n 'CorePlatform'
tmux set remain-on-exit $remainOnExit
tmux split-window -v -p 90 -c $root/cmd/mock-coreplatform "go install && mock-coreplatform -localStack=true -localDocker=true $enableTokenizer  | tee $LOG_DIR/mock-coreplatform.log"

echo "Starting Mastercard Clearing Job"
# Create/configure auth window
tmux new-window -t mock-service-test-harness -n 'Test Harness'
tmux set remain-on-exit $remainOnExit
tmux split-window -v -p 90 -c $root/cmd/test-harness "go install && test-harness -localStack=true -localDocker=true $enableTokenizer  | tee $LOG_DIR/test-harness.log"

echo "Attaching to api window"
tmux attach-session -t mock-service-test-harness

exit 0
