#!/bin/bash

function check_params() {
     missing=()

     for key in ${!required[@]}
     do
          if [ -z "${params[${key}]}" ]
          then
               missing+=(${key})
          fi
     done

     if [ ${#missing[@]} -ne 0 ]
     then
          echo -n "Missing argument"

          if [ ${#missing[@]} -gt 1 ]
          then
               echo -n "s"
          fi

          echo -n ": "

          IFS=$'\n' missing_sorted=($(sort <<< "${missing[*]}"))
          unset IFS

          missing_str=$(printf ", --%s" "${missing_sorted[@]}")

          echo -e "${missing_str:2}\n"

          usage

          exit 1
     fi
}

function fix_provision_data() {
     vm_dir=${params[vm-data-dir]}

     rm -rf ${vm_dir}/provision_data_fixed
     cp -R ${vm_dir}/provision_data ${vm_dir}/provision_data_fixed

     for filename in $(ls ${vm_dir}/provision_data_fixed)
     do
          for key in ${!params[@]}
          do
               sed -i 's^{{'"${key}"'}}^'"${params[${key}]}"'^g' ${vm_dir}/provision_data_fixed/${filename}
          done
     done
}

function get_builder_required_params() {
     # Based on the builder type, there will be several implicitly required parameters.

     builder_type=$(jq -r '.builder_type' ${1} 2> /dev/null)

     case ${builder_type} in
          esxi)
               required[esxi-datastore-cache-directory]=true
               required[esxi-datastore-cache-name]=true
               required[esxi-datastore-name]=true
               required[esxi-hostname]=true
               required[esxi-password]=true
               required[esxi-username]=true
               required[vm-esxi-cpus]=true
               required[vm-esxi-disk-size]=true
               required[vm-esxi-network]=true
               ;;

          *)
               echo "Invalid builder_type '${builder_type}' specified in ${1}"

               exit 1
               ;;
     esac
}

function get_params() {
     while [ ! -z "${1}" ]
     do
          case ${1} in
               --?*)
                    key=${1:2}
                    shift
                    value=${1}
                    shift

                    if [ ! -z "${value}" ]
                    then
                         params[${key}]=${value}
                    fi
                    ;;
          esac
     done
}

function init() {
     for key in $(jq -r '.defaults | keys[]' ${1} 2> /dev/null)
     do
          defaults[${key}]=$(jq -r ".defaults[\"${key}\"]" ${1})
          params[${key}]=${defaults[${key}]}
     done

     for key in $(jq -r '.descriptions | keys[]' ${1} 2> /dev/null)
     do
          descriptions[${key}]=$(jq -r ".descriptions[\"${key}\"]" ${1})
     done

     for key in $(jq -r '.required[]' ${1} 2> /dev/null)
     do
          required[${key}]=true
     done
}

function init_images() {
     for key in $(jq -r '. | keys[]' ${1} 2> /dev/null)
     do
          image_names[${key}]=found
          
          for subkey in $(jq -r ".\"${key}\" | keys[]" ${1} 2> /dev/null)
          do
               images[${key}.${subkey}]=$(jq -r ".\"${key}\".\"${subkey}\"" ${1} 2> /dev/null)
          done
     done
}

function params_to_json() {
     result="{\"params\":{"
     temp_file=$(mktemp)

     for key in ${!params[@]}
     do
          key_fixed=$(echo ${key} | sed 's/-/_/g')

          result+="\"${key_fixed}\":\"${params[${key}]}\","
     done

     echo ${result::-1}"}}" >> ${temp_file}
     echo ${temp_file}
}

function run_packer() {
     temp_file=$(params_to_json)
     cmd="(cd ${1} && PACKER_KEY_INTERVAL=10 packer build -var ansible-requirements=${1}/ansible/requirements.yml"
     cmd+=" -var ansible-playbook=${params[vm-data-dir]}/ansible/main.yml"

     for key in ${!params[@]}
     do
          cmd+=" -var ${key}=\"${params[${key}]}\""
     done

     cmd+=" -var json_vars=${temp_file}"

     # Add the Packer provisioner and image variables based on which params are marked as # required (these values were
     # already set based on the builder_type specified in variables.json).

     case ${builder_type} in
          esxi)
               cmd+=" -var vm-esxi-iso-checksum=\"${images[${params[vm-image]}.iso-checksum]}\""
               cmd+=" -var vm-esxi-iso-checksum-type=\"${images[${params[vm-image]}.iso-checksum-type]}\""
               cmd+=" -var vm-esxi-iso-url=\"${images[${params[vm-image]}.iso-url]}\""
               cmd+=" -only vmware-iso"
               ;;
     esac

     cmd+=" ${1}/${images[${params[vm-image]}.packer-file]}; rm -f ${temp_file})"

     eval ${cmd}
}

function usage() {
     echo -e "Usage: ${0} [options...]\n\nOptions:\n"

     # Order the descriptions here since we have pulled in a second set of descriptions from the vm-data-dir directory.

     IFS=$'\n' descriptions_ordered=($(sort <<<"${!descriptions[*]}"))
     unset IFS

     for index in ${!descriptions_ordered[@]}
     do
          key=${descriptions_ordered[${index}]}

          echo -e -n "\t--${key} ["

          # Manually handle vm-image since the list of acceptable values is determined by the list of available images.

          if [ "${key}" == "vm-image" ]
          then
               names=""

               for name in ${!image_names[@]}
               do
                    names+="|'${name}'"
               done

               echo -n "${names:1}"
          else
               echo -n "value"
          fi

          if [ ! -z "${defaults[${key}]}" ]
          then
               echo -n ", default='${defaults[${key}]}'"
          fi

          echo -n "];"

          if [ ! -z "${required[${key}]}" ]
          then
               echo -n "(required)"
          else
               echo -n " "
          fi

          echo ";${descriptions[${key}]}"
     done | column -s ';' -t
}

dir_script=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
dir_packer=${dir_script}/packer

declare -A defaults
declare -A descriptions
declare -A image_names
declare -A images
declare -A params
declare -A required

init_images ${dir_packer}/images.json
init ${dir_packer}/variables.json

get_params "${@}"

# Also run init on the vm-data-dir directory so we can get defaults, descriptions, and required parameters.

params[vm-data-dir]=$(readlink -f ${params[vm-data-dir]} 2> /dev/null)

if [ ! -f ${params[vm-data-dir]}/variables.json ]
then
     echo -e "Could not read variables file ${params[vm-data-dir]}/variables.json\n"

     usage

     exit 1
fi

get_builder_required_params ${params[vm-data-dir]}/variables.json

init ${params[vm-data-dir]}/variables.json

# Run this again... the first time is to get the vm-data-dir parameter.

get_params "${@}"

params[vm-data-dir]=$(readlink -f ${params[vm-data-dir]} 2> /dev/null)

# Create MAC address from hostname.

params[vm-mac-address]=$(echo ${params[vm-hostname]} | md5sum | \
     sed 's/^\(..\)\(..\)\(..\)\(..\)\(..\).*$/02:\1:\2:\3:\4:\5/')

check_params

echo -e "MAC address for host ${params[vm-hostname]}: ${params[vm-mac-address]}\n"

fix_provision_data

run_packer ${dir_packer}

rm -rf ${vm_dir}/provision_data_fixed