#!/bin/bash

service_mgt() {
  action="$1"
  name="$2"
  if [[ -L '/sbin/init' ]]; then
    systemctl "$action" "$name" -l --no-pager
  else
    service "$name" "$action"
  fi
  return $?
}

echo "Stopping sssd service and clearing cache."
service_mgt "stop" "sssd"
rm -rf /var/lib/sss/db/* /var/lib/sss/mc/*

echo "Restarting sssd services."
service_mgt "start" "sssd"
service_mgt "restart" "autofs"

service_mgt "status" "sssd"
service_mgt "status" "autofs"
