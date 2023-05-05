#!/usr/bin/env bash
#
# Description: Script to get the SSL certificate chain and certificate dates.
#              This script needs to run as the root user.
# Date       Author               Description
# ---------- ------------------- ---------------------------------------------------------
# 04/26/2022 Jimmy Garagorry      Created
#==========================================================================================

# Function: run_as_root_check - Double-check if root is executing the script {{{1
#-----------------------------------------------------------------------
function run_as_root_check () 
{
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color

    # Need to run the script as the root user
    if [[ $(id -u) -ne 0 ]]
    then
        echo -e "You are not the -->> ${RED}root${NC} <<-- user. Please execute: >> ${GREEN}sudo -i${NC} << then execute ${GREEN}$0${NC} again"
        exit 1
    fi
}

# Function: do_check_ssl_certificates - Get the SSL certificate Chain {{{1
#-----------------------------------------------------------------------
function do_check_ssl_certificates () 
{
    if [[ $# -ne 3 ]]
    then
        echo "USAGE: $0 'RUNS FQDN PORT'"
        exit 1
    else
        export RUNS=$1
        export HOST_FQDN=$2
        export HOST_SSL_PORT=$3
        export BASE_DIR=/tmp/cldr_ssl_$(date +"%Y%m%d%H%M%S")
    fi
    COUNT=1
    while (( COUNT <= RUNS ))
    do
        mkdir ${BASE_DIR}_${HOST_FQDN}_${COUNT}
        cd ${BASE_DIR}_${HOST_FQDN}_${COUNT}
        echo "...[${COUNT}/${RUNS}]..."
        openssl s_client -connect ${HOST_FQDN}:${HOST_SSL_PORT}  -showcerts </dev/null 2>/dev/null | awk '/BEGIN/,/END/{ if(/BEGIN/){a++}; out="cert"a".crt"; print >out}'
        for cert in *.crt
        do
            newname=$(openssl x509 -noout -subject -in $cert | sed -n 's/^.*CN=\(.*\)$/\1/; s/[ ,.*]/_/g; s/__/_/g; s/^_//g;p').pem
            if [[ -f ${newname} ]]
            then
                mv ${cert} ${newname}_1
            else
                mv ${cert} ${newname}
            fi
        done
        for i in *.pem*
        do
            echo -e "\n${YELLOW}${i}:${NC}\n"
            #openssl x509 -noout -subject -issuer -dates -inform PEM -in ${i}
            openssl x509 -noout -subject -issuer -dates -inform PEM -text -certopt no_subject,no_header,no_version,no_serial,no_signame,no_validity,no_issuer,no_pubkey,no_sigdump,no_aux -in ${i}
            echo
        done
        sleep 5
        (( COUNT += 1 ))
    done
}

# Function: main - Call the actions {{{1
#-----------------------------------------------------------------------
function main () 
{
    # Color Codes:
    # ===========
    # Black        0;30     Dark Gray     1;30
    # Red          0;31     Light Red     1;31
    # Green        0;32     Light Green   1;32
    # Brown/Orange 0;33     Yellow        1;33
    # Blue         0;34     Light Blue    1;34
    # Purple       0;35     Light Purple  1;35
    # Cyan         0;36     Light Cyan    1;36      
    # Light Gray   0;37     White         1;37
    # -------------------------------------------------------------------
    export RED='\033[0;31m'
    export GREEN='\033[0;32m'
    export YELLOW='\033[0;33m'
    export BLUE='\033[0;34m'
    export NC='\033[0m' # No Color

    run_as_root_check
    do_check_ssl_certificates $1 $2 $3    
}

main $1 $2 $3 
exit 0