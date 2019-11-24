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
BOLD='\033[1m'
NC='\033[0m'

PRINT_HELP () {
    printf "\n
${BOLD}NAME${NC}\n
    measure-script-time -- measure the execution time of a process before and after a change \n
${BOLD}SYNOPSIS${NC}\n
    ${BOLD}measure-script-time${NC} [${BOLD}-c${NC} <command (npm t)>] [${BOLD}-p${NC} <path to results (~/temp/measure-script-time/results)>] [${BOLD}-b${NC} <before state>] [${BOLD}-a${NC} <after state>] [${BOLD}-n${NC} <number of runs (5)>] [${BOLD}-l${NC} <number of lines to include in base log>]\n
${BOLD}DESCRIPTION${NC}\n
    A command line script that allows measuring the execution time of a command line script\n
    The command uses ${BOLD}time${NC} command in order to check the performance of the script\n
    The execution order is as follows:\n
    do ${BOLD}--number-of-runs${NC} times:\n
        * Run init before command \n
        * Run the script \n
        * Write full log to ${BOLD}--results-path${NC}/logs-full/current-run.before.<index>.txt \n
        * Write the last ${BOLD}--tail-amount${NC} lines of the log to ${BOLD}--results-path${NC}/results.before.txt \n
        * Write the output of ${BOLD}time${NC} to ${BOLD}--results-path${NC}/times.txt file \n\n
        * Run init after command \n
        * Run the script \n
        * Write full log to ${BOLD}--results-path${NC}/logs-full/current-run.after.<index>.txt \n
        * Write the last ${BOLD}--tail-amount${NC} lines of the log to ${BOLD}--results-path${NC}/results.after.txt \n
        * Write the output of ${BOLD}time${NC} to ${BOLD}--results-path${NC}/times.txt file \n
\n
    The options are as follows (the default):
        ${BOLD}-c | --command${NC}          The command to measure (npm t) \n
        ${BOLD}-p | --results-path${NC}     The location to write the execution results to - will be created if not exists (~/temp/measure-script-time/results) \n
        ${BOLD}-b | --init-before${NC}      The command to run in order to initialize the environment before the change to measure - if not set, the measurement will be for the script after the change only \n
        ${BOLD}-a | --init-after${NC}       The script to run in order to initialize the change to measure (git checkout master) \n
        ${BOLD}-n | --number-of-runs${NC}   How many times should the script be executed before and after (5) \n
        ${BOLD}-l | --tail-amount${NC}      How lines from the script execution should be written to ${BOLD}--results-path${NC}/results.(before|after).txt (10) \n
${BOLD}EXAMPLES${NC}\n
    The command:\n
        measure-script-time -c \"npm run test\" -p ~/tmp/results -b \"npm install some-lib@2\" -a \"npm install some-lib@3\" \n
    Will measure the execution time of 'npm run test' with version 2 compared to 3 of 'some-lib' npm library \n
    The command:\n
        measure-script-time -c \"npm run test\" -p ~/tmp/results -a \"\" \n
    Will measure the execution time of 'npm run test' without any initialization script and will compare it to nothing \n
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
