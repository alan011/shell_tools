#!/bin/bash

project=$1            # Required
env_name=$2           # Required
version=$3            # Required
container=$4          # Optional. Default: $project.

env_vars=""
remote_host=""
remote_script=`date +'%s.%N'`.sh

test_remote_host="172.16.1.110"
pre_remote_host="172.16.1.78"
bank_remote_host="10.0.1.174"
bbbank_remote_host="10.0.2.115"

namespace="loan-backend"

function usage() {
cat << EOF
Usage:
    ./set_envvars.sh <project> <env_name> <version> [<container>]

This scripts require a directory 'projects' with structure like this:

projects/
|-- in-loan-mng                     # project: in-loan-mng.
|   |-- bank                        # env_name: bank.
|   |-- bbbank
|   |-- pre
|   |-- test
|-- redis-test-tmp
|   |-- bank
|   |   |-- RT023-in-loan-mng.env   # version: RT023, container: in-loan-mng
|   |   ...
|   |-- bbbank
|   |   |-- RT023-in-loan-mng.env
|   |   ...
|   |-- pre
|   |   |-- RT023-in-loan-mng.env
|   |   ...
|   |-- test 
|   ...

In env_file 'RT023-in-loan-mng.env' contents should be like this:

ENV_NAME1=value1                    # To add or reset a env var 'ENV_NAME1'
ENV_NAME2=value2                   
ENV_NAME3-                          # '-' means to remove this env var.
...

EOF

}

function check() {
    [ -z "$project" ]  && usage && echo -e "\nERROR: Wrong usage." && exit 1
    [ -z "$env_name" ] && usage && echo -e "\nERROR: Wrong usage." && exit 1
    [ -z "$version" ]  && usage && echo -e "\nERROR: Wrong usage." && exit 1
    [ -z "$container"] && container=$project
    
    env_file=projects/${project}/${env_name}/${version}-${container}.env
    [ ! -f $env_file ]  && usage && echo -e "\nERROR: env file not exist: ${env_file}" && exit 1
}

function make_remote_script(){
    for pair in `cat $env_file`; do
        if [[ $pair =~ [A-Z0-9_]+=.+ ]]; then
            env_vars="$env_vars $pair"
        elif [[ $pair =~ [A-Z0-9_]+- ]]; then
            env_vars="$env_vars $pair"
        else
            echo "Warning: Illegal env pair '${pair}' found in env file '${env_file}'. this pair has been ignored."
        fi
    done
    echo "env_vars: $env_vars"
    echo "kubectl set env deployment/${project} -c '${container}' -n ${namespace} ${env_vars}" > tmp/$remote_script
    
}

function get_remote_host() {
    [ "$env_name" == "test" ]   && remote_host=$test_remote_host
    [ "$env_name" == "pre" ]    && remote_host=$pre_remote_host
    [ "$env_name" == "bank" ]   && remote_host=$bank_remote_host
    [ "$env_name" == "bbbank" ] && remote_host=$bbbank_remote_host
}

function ansible_call(){
    ansible-playbook -i ${remote_host}, -e "remote_script=${remote_script}" ./set_k8s_envvars.yml --private-key=/root/.ssh/id_rsa
}

#--------------- main ---------------

check
get_remote_host
make_remote_script
ansible_call

