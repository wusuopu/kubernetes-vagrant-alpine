#!/bin/sh

export PATH=/usr/share/cni-plugins/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
master_host_ip=$2
node_num=$1
if [[ "${master_host_ip}" = "" ]]; then
  master_host_ip=$KUBE_MASTER_HOST_IP
fi
if [[ "${node_num}" = "" ]]; then
  node_num=$KUBE_NODE_NUM
fi
interface=eth0
IPADDR=$(ip a show $interface | grep "inet " | awk '{print $2}' | cut -d / -f1)
echo master_host_ip: $master_host_ip
echo node_num: $node_num
echo current ip: $IPADDR

mkdir -p /vagrant/tmp/log
logfile=/vagrant/tmp/log/k3s-${node_num}.log

wait_master () {
  max_retry=5
  retry=0
  while [[ $retry -lt $max_retry ]]; do
    echo "wait_master ${retry}"
    sleep 5
    kubectl get nodes &> /dev/null
    if [[ $? = 0  ]]; then
      return $retry
    fi
    retry=`echo $retry+1|bc`
    if [[ $retry -gt $max_retry ]]; then
      return $retry
    fi
  done
  return $retry
}
start_master () {
  echo 'start master'
  k3s server --docker --flannel-iface=$interface --node-ip=$IPADDR --log $logfile &
  wait_master

  NODE_TOKEN="/var/lib/rancher/k3s/server/node-token"
  sudo cp -v ${NODE_TOKEN} /vagrant/
  sudo cp -v /etc/rancher/k3s/k3s.yaml /vagrant/
}

start_agent () {
  echo 'start agent'
  k3s_url=https://$master_host_ip:6443
  node_token=$(cat /vagrant/node-token)
  k3s agent --docker --flannel-iface=$interface --node-ip=$IPADDR --log $logfile --server=$k3s_url --token ${node_token} &
}

start_k3s () {
  if [[ "${master_host_ip}" = "" ]]; then
    echo "master_host_ip is not set"
    exit 1
  fi
  if [[ "${node_num}" = "" ]]; then
    echo "node_num is not set"
    exit 1
  fi

  if [[ $node_num == 1 ]]; then
    start_master
  else
    start_agent
  fi
}

start_k3s
