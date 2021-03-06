#!/bin/bash

## Create local-storage namespace and subscription to Local Storage operator
cat << EOF | oc apply -f -
apiVersion: v1
kind: Namespace
metadata:
  labels:
    openshift.io/cluster-monitoring: "true"
  name: openshift-cnv
spec: {}
---
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: openshift-cnv-group
  namespace: openshift-cnv
spec:
  targetNamespaces:
  - openshift-cnv
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: kubevirt-hyperconverged
  namespace: openshift-cnv
spec:
  channel: "2.3"
  installPlanApproval: Automatic
  name: kubevirt-hyperconverged
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF

### Sleep for 15s while Operator Subscription initializes
echo "Waiting for 20s while the Operator Initializes"
sleep 20

cat << EOF | oc apply -f -
apiVersion: hco.kubevirt.io/v1alpha1
kind: HyperConverged
metadata:
  name: kubevirt-hyperconverged
  namespace: openshift-cnv
spec:
  BareMetalPlatform: true
EOF