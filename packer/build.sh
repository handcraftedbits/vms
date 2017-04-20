#!/bin/bash

function usage () {
     echo "usage: ${0} [digitalocean|esxi] [16.04|16.10|17.04] [hostname]"

     exit 1
}

dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

case "${1}" in
     digitalocean)
          provisioner=digitalocean
          ;;
     esxi)
          provisioner=vmware-iso
          ;;
     *)
          usage
esac

case "${2}" in
     16.04)
          checksum=2bce60d18248df9980612619ff0b34e6
          image=ubuntu-16-04-x64
          url=http://releases.ubuntu.com/16.04/ubuntu-16.04.2-server-amd64.iso
          ;;
     16.10)
          checksum=7d6de832aee348bacc894f0a2ab1170d
          image=ubuntu-16-10-x64
          url=http://releases.ubuntu.com/16.10/ubuntu-16.10-server-amd64.iso
          ;;
     17.04)
          checksum=4672ce371fb3c1170a9e71bc4b2810b9
          image=ubuntu-17-04-x64
          url=http://releases.ubuntu.com/17.04/ubuntu-17.04-server-amd64.iso
          ;;
     *)
          usage
esac

if [ "${3}" == "" ]
then
     usage
fi

(cd "${dir}" && PACKER_KEY_INTERVAL=10 packer build -var-file="${dir}/../${3}/variables-${1}.json" \
     -var "host-dir=${dir}/../${3}" -var "iso-checksum=${checksum}" -var "iso-url=${url}" \
     -var "playbook=${dir}/../${3}/ansible/main.yml" \
     -var "roles-path=${dir}/ansible/roles:${dir}/../${3}/ansible/roles" -var "ubuntu-image=${image}" \
     -var "ubuntu-version=${2}" -only="${provisioner}" "${dir}/vm-ubuntu.json")