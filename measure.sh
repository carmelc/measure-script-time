#!/bin/bash

# Defaults
COMMAND="npm t"
RESULTS_PATH=~/temp/measure-script-time/results
INIT_BEFORE=""
INIT_AFTER="git checkout master"
NUMBER_OF_RUNS=5
NUMBER_OF_LINES_TO_TAIL=10
SHOULD_RUN='true'
SHOULD_RUN_BEFORE='true'

GREEN='\033[0;32m'
WARNING_COLOR='\033[1;33m'
NC='\033[0m'

PRINT_HELP () {
    printf "\
usage measure [-c] <command (npm t)> [-p <path to results (~/temp/measure-script-time/results)>] [-b <before state>] [-a <after state>] [-n <number of runs (5)>] [-l <number of lines to include in base log>]\

Full Details:
TBD
"
}

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -c|--command)
    COMMAND="$2"
    shift # past argument
    shift # past value
    ;;
    -p|--results-path)
    RESULTS_PATH=$2
    shift # past argument
    shift # past value
    ;;
    -b|--init-before)
    INIT_BEFORE="$2"
    shift # past argument
    shift # past value
    ;;
    -a|--init-after)
    INIT_AFTER="$2"
    shift # past argument
    shift # past value
    ;;
    -n|--number-of-runs)
    NUMBER_OF_RUNS="$2"
    shift # past argument
    shift # past value
    ;;
    -l|--tail-amount)
    NUMBER_OF_LINES_TO_TAIL="$2"
    shift # past argument
    shift # past value
    ;;
    -h|--help)
    PRINT_HELP
    SHOULD_RUN='false'
    shift # past argument
    ;;
    --default)
    DEFAULT=YES
    shift # past argument
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

run_test () {
    local TYPE=$1
    local TYPE_UPPER=$2
    local i=$3
    printf "\n-------- Run #${i} ${TYPE_UPPER} ----------\n" >> ${RESULTS_PATH}/times.txt
    printf "Run #${i} ${TYPE_UPPER}" >> ${RESULTS_PATH}/results.${TYPE}.txt
    (time ${COMMAND} > ${RESULTS_PATH}/logs-full/current-run.${TYPE}.${i}.txt 2>&1) 2>> ${RESULTS_PATH}/times.txt
    printf "\n\n\n########### Run #${i} ################\n" >> ${RESULTS_PATH}/results.${TYPE}.txt
    tail -n ${NUMBER_OF_LINES_TO_TAIL} ${RESULTS_PATH}/logs-full/current-run.${TYPE}.${i}.txt >> ${RESULTS_PATH}/results.${TYPE}.txt
}

run () {
    for i in $(seq 1 ${NUMBER_OF_RUNS})
    do
        printf "\n\n\n########### Run #${i} ################\n" >> ${RESULTS_PATH}/times.txt

        if [[ "${SHOULD_RUN_BEFORE}" == 'true' ]]
        then
            ${INIT_BEFORE}
            run_test "before" "BEFORE" $i
        fi

        ${INIT_AFTER}

        run_test "after" "AFTER" $i

        printf "\n########### Run #${i} - DONE ################" >> ${RESULTS_PATH}/times.txt

    done
}

init() {
    printf "${GREEN}Running Command: ${COMMAND}${NC}\n"
    printf "Results will be stored in ${RESULTS_PATH}\n"
    printf "Testing ${NUMBER_OF_RUNS} times the difference between before: '${INIT_BEFORE}' and ${INIT_AFTER}\n"

    if [[ "${INIT_BEFORE}" == '' ]]
    then
        printf "${WARNING_COLOR}Warning: No init before command is defined, running only 'after' part${NC}\n"
        SHOULD_RUN_BEFORE='false'
    fi

    printf "Starting Runs\n"
    mkdir -p ${RESULTS_PATH}/logs-full
    printf "Running Tests\n" > ${RESULTS_PATH}/times.txt
    printf "Running Tests\n\n" > ${RESULTS_PATH}/results.before.txt
    printf "Running Tests\n\n" > ${RESULTS_PATH}/results.after.txt
}

if [[ "${SHOULD_RUN}" == 'true' ]]
then
    init
    run
fi
