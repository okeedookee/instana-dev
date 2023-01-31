
#!/bin/bash
wait_for() {
  CMD=$1
  MAX=${2:-20}
  n=0
  success=false
  until [ $n -ge $MAX ]
  do
    $CMD && success=true && break
    n=$[$n+1]
    echo -n "."
    sleep 1
  done
  if [ "$success" = false ]; then
    printf "\nTimed out after $MAX seconds.\n"
    exit 1
  fi
}

check_butler() {
  curl http://localhost:8480 -s
}

check_gk() {
  curl http://127.0.0.1:8280 -s
}

#
screen -list
echo "Kill all screens..."
pkill screen
sleep 5

rm /tmp/*.log
#
echo "Start butler..."
screen -dm -L -S bulter -Logfile /tmp/butler.log -L  ~/backend/dev/scripts/start-component.sh butler
wait_for check_butler 1024

echo "Start Groundskeeper"
screen -dm -L -S groundskeeper -Logfile /tmp/groundskeeper.log ~/backend/dev/scripts/start-component.sh groundskeeper
wait_for check_gk 1024

if [[ -z $export INSTANA_AGENT_KEY ]]; then
  exit -1
fi
~/backend/dev/scripts/create-local-test-user.sh | jq .

sleep 5

# screen -dm -S  -L -Logfile /tmp/.log ~/backend/dev/scripts/start-component.sh

# for c in acceptor filler appdata-processor appdata-reader appdata-writer issue-tracker processor ui-backend; do
# for c in acceptor filler appdata-processor appdata-reader appdata-writer ui-backend issue-tracker processor logging/log-processor logging/log-writer logging/log-reader; do
for c in acceptor filler appdata-processor appdata-reader appdata-writer ui-backend; do
  echo "Start component: $c ..."
  screen -dm -L -S $c -Logfile /tmp/$c.log ~/backend/dev/scripts/start-component.sh $c
  sleep 5
done

