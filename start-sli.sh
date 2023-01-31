#!/bin/bash

for c in sli-beacons-filter  sli-calls-filter  sli-data-reader  sli-data-writer  sli-evaluator; do
  echo "Start sli component: $c ..."
  pushd ~/backend/service-level-objectives/$c
  screen -dm -L -S $c -Logfile /tmp/$c.log gradle run --args="server /root/backend/dev/configs/local-${c}.yaml"
  popd
  sleep 5
done
