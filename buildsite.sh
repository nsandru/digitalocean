#!/bin/sh

export TF_VAR_domain=$1
export TF_VAR_region=$2

test -z "$2" && {
  echo Usage: $0 domain zone '[number of gateways] [number of docker servers]'
  exit 2
}

REGIONEXISTS=`dig +short ns $TF_VAR_region.$TF_VAR_domain | wc -l`
test $REGIONEXISTS -gt 0 && {
  export TF_VAR_createdomain=0
} || {
  export TF_VAR_createdomain=1
}

echo 'locahost ansible_connection=local' > ansible/inventory
(cd ansible ; ansible-playbook localhost.yml -i inventory)

for DIR in gateway dockerserver ; do
  export TF_VAR_instances=$3
  test 0$TF_VAR_instances -lt 2 && export TF_VAR_instances=2
  test -f $DIR/main.tf && {
    ( cd $DIR
      rm -f terraform.tfstate*
      terraform init
      terraform plan
      terraform apply
    )
    echo '['$DIR']' >> ansible/inventory
    echo ${DIR}'['0:`expr $TF_VAR_instances - 1`']'.$TF_VAR_region.$TF_VAR_domain >> ansible/inventory
    echo >> ansible/inventory
    export TF_VAR_createdomain=0
  }
  shift
done
sleep 30
for HOST in `ansible all -i ansible/inventory --list | grep "$TF_VAR_region.$TF_VAR_domain"`
do
  ssh-keyscan $HOST >> $HOME/.ssh/known_hosts
done



