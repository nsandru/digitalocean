#!/bin/sh

test $1 || {
  echo Usage: $0 region.domain [number of instances]
  exit 1
}

REGDOMAIN=$1
INSTANCES=$2

REGION=`echo $REGDOMAIN | cut -f1 -d.`
DOMAIN=`echo $REGDOMAIN | cut -f2- -d.`

INTDOMAINS=`(cd ansible/var/named ; ls *.internal | sed 's/\.internal$//')`
INTDOMAINS=`echo $INTDOMAINS | tr ' ' ','`
EXTDOMAINS=`(cd ansible/var/named ; ls *.external | sed 's/\.external$//')`
EXTDOMAINS=`echo $EXTDOMAINS | tr ' ' ','`

test -f ansible/etc/0.external || {
  (cat << EOF
      allow-query { any; };
EOF
) > ansible/etc/0.external
}

test "x$INTDOMAINS" = x -o "x$EXTDOMAINS" = x && {
  echo $0: Populate ansible/var/named with at least one internal zone file and one external zone file
  exit 1
}

test 0$INSTANCES -eq 0 && INSTANCES=2

terraform init

TF_VAR_region=$REGION TF_VAR_domain=$DOMAIN TF_VAR_instances=$INSTANCES terraform plan
TF_VAR_region=$REGION TF_VAR_domain=$DOMAIN TF_VAR_instances=$INSTANCES terraform apply

sleep 60

(cd ansible
 echo "dnsserver[0:`expr $INSTANCES - 1`].$REGDOMAIN" > inventory
 for HOST in `ansible all -i inventory --list | grep $REGDOMAIN` ; do
   sed -i "/^$HOST/d" $HOME/.ssh/known_hosts
 done
 ansible-playbook namedconf.yml -i inventory --ssh-common-args="-o StrictHostKeyChecking=false" -e intdomain=$INTDOMAINS -e extdomain=0,$EXTDOMAINS -u root
)

exit 0
