#!/bin/bash
while [ ! -f /root/ocp4upi/artifacts/install/auth/kubeconfig ]; do
    sleep 2
done
sleep 300
export KUBECONFIG="/root/ocp4upi/artifacts/install/auth/kubeconfig";
export oc=/root/ocp4upi/artifacts/oc
($oc get csr -oname | xargs $oc adm certificate approve) || true
sleep 180
workersrequested=$(yq r /root/ocp4upi/artifacts/install/install-config.yaml.backup compute.[0].replicas)
workersapproved=0
until [ $workersapproved -eq $workersrequested ]; do
    $oc get csr -ojson | jq -r '.items[] | select(.status == {} ) | .metadata.name' | xargs oc adm certificate approve 2> >(sed -e 's/^error.*CSRs\ must\ be\ specified.*/Continue\ CSR\ approval\ loop/' >&2);
    sleep 10  
    workersapproved=$($oc get csr | grep -v NAME | grep worker | grep Approved | wc -l);
done