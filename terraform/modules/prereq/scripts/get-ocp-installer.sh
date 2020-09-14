#!/bin/bash

RDIR=$1
OCP_VERSION=$2

[ -d $RDIR/artifacts/install ] && echo "install subdirectory exists" || mkdir -p $RDIR/artifacts/install

if [ -f $RDIR/artifacts/openshift-install.tar.gz ] && [ -f $RDIR/artifacts/oc.tar.gz ] ; then
	echo 'Openshift Installer Exists'
else
	curl http://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest-${OCP_VERSION}/openshift-install-linux.tar.gz \
		--output $RDIR/artifacts/openshift-install.tar.gz;
        curl http://mirror.openshift.com/pub/openshift-v4/clients/oc/latest/linux/oc.tar.gz \
                --output $RDIR/artifacts/oc.tar.gz;
fi

cd $RDIR/artifacts;
tar -xvzf openshift-install.tar.gz;
tar -xvzf oc.tar.gz;
cp oc /usr/local/bin/oc || true
