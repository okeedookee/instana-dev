#!/bin/bash
uiclientdir="/root/ui-client"
backenddir="/root/backend"

die()
{
	local _ret="${2:-1}"
	test "${_PRINT_HELP:-no}" = yes && print_help >&2
	echo "$1" >&2
	exit "${_ret}"
}


begins_with_short_option()
{
	local first_option all_short_options='rsuafh'
	first_option="${1:0:1}"
	test "$all_short_options" = "${all_short_options/$first_option/}" && return 1 || return 0
}

# THE DEFAULTS INITIALIZATION - OPTIONALS
_arg_run=
_arg_stop=
_arg_all=
_arg_ui=


print_help()
{
	printf '%s\n' "Script to help start backend services"
	printf 'Usage: %s [-r|--run <arg>] [-s|--stop <arg>] [-h|--help]\n' "$0"
	printf '\t%s\n' "-r, --run: Run Components in screen (no default)"
	printf '\t%s\n' "-s, --stop: Stop Components in screen (no default)"
        printf '\t%s\n' "-u, --ui start: Start ui screen"
	printf '\t%s\n' "-a, --all: Pull git and restart backend and client-ui"
        printf '\t%s\n' "-f, --filler: restart elastic search - start filler, processor, and issue-tracker"
	printf '\t%s\n' "-h, --help: Prints help"

}


parse_commandline()
{
	while test $# -gt 0
	do
		_key="$1"
		case "$_key" in
			-r|--run)
				_arg_run="true"
				shift
				;;
			--run=*)
				_arg_run="true"
				;;
			-r*)
				_arg_run="true"
				;;
         -f|--filler)
				_arg_filler="true"
				shift
				;;
			--filler=*)
				_arg_filler="true"
				;;
			-f*)
				_arg_filler="true"
				;;
			-a|--a)
				_arg_all="true"
				shift
				;;
			--a=*)
				_arg_all="true"
				;;
			-a*)
				_arg_all="true"
				;;
			-s|--stop)
				_arg_stop="true"
				shift
				;;
			--stop=*)
				_arg_stop="true"
				;;
			-s*)
				_arg_stop="true"
				;;
            -u|--u)
				_arg_ui="true"
				shift
				;;
			--ui=*)
				_arg_ui="true"
				;;
			-u*)
				_arg_ui="true"
				;;
			-h|--help)
				print_help
				exit 0
				;;
			-h*)
				print_help
				exit 0
				;;
			*)
				_PRINT_HELP=yes die "FATAL ERROR: Got an unexpected argument '$1'" 1
				;;
		esac
		shift
	done
}

stop_screen() {
    screen -ls | grep Detached | cut -d. -f1 | awk '{print $1}' | xargs kill
    echo "Killing screens"
    while true;do echo -n .;sleep 1;done &
    sleep 25 # or do something else here
    kill $!; trap 'kill $!' SIGTERM
    echo done
    screen -ls

}

start_screen() {
 instanadir="$backenddir/dev/scripts"
    echo "+++++++++ Starting butler component on screen butler +++++++++"
    screen -S butler -dm bash -c "$instanadir/start-component.sh butler"
    echo "+++++++++ Starting groundkeeper component on screen groundkeeper  +++++++++"
    screen -S groundkeeper -dm bash -c "$instanadir/start-component.sh groundskeeper"

    echo "+++++++ Waiting ~2 minutes for butler and groundkeeper +++++"

    while true;do echo -n .;sleep 1;done &
    sleep 100  # or do something else here
    kill $!; trap 'kill $!' SIGTERM
    echo done

    echo "+++++++++ Starting acceptor component on screen acceptor  +++++++++"
    screen -S acceptor -dm bash -c "$instanadir/start-component.sh acceptor"
    while true;do echo -n .;sleep 1;done &
    sleep 100  # or do something else here
    kill $!; trap 'kill $!' SIGTERM
    echo done

    echo "+++++++++ Starting filler component on screen  filler  +++++++++"
    screen -S filler -dm bash -c "$instanadir/start-component.sh filler"

    echo "+++++++++ Starting ui-backend component on screen ui-backend  +++++++++"
    screen -S ui-backend -dm bash -c "$instanadir/start-component.sh ui-backend"

    echo "+++++++++ Starting appdata-processor component on screen appdata-processor  +++++++++"
    screen -S appdata-processor -dm bash -c "$instanadir/start-component.sh appdata-processor"

    echo "+++++++++ Starting appdata-reader component on screen appdata-reader  +++++++++"
    screen -S appdata-reader -dm bash -c "$instanadir/start-component.sh appdata-reader"

    echo "+++++++++ Starting appdata-writer component on screen appdata-writer  +++++++++"
    screen -S appdata-writer -dm bash -c "$instanadir/start-component.sh appdata-writer"

    echo "Starting Event components"
    while true;do echo -n .;sleep 1;done &
    sleep 45 # or do something else here
    kill $!; trap 'kill $!' SIGTERM
    echo done

    echo "+++++++++ Issue Tracker  +++++++++"
    screen -S issue-tracker -dm bash -c "$instanadir/start-component.sh issue-tracker"

    echo "+++++++++ Processor  +++++++++"
    screen -S processor -dm bash -c "$instanadir/start-component.sh processor"


    echo "+++++++++ Log processor  +++++++++"
    screen -S log-processor -dm bash -c "$instanadir/start-component.sh logging/log-processor"

    echo "+++++++++ Log writer  +++++++++"
    screen -S log-writer -dm bash -c "$instanadir/start-component.sh logging/log-writer"

    echo "+++++++++ Log reader  +++++++++"
    screen -S log-reader -dm bash -c "$instanadir/start-component.sh logging/log-reader"

    # work around ES losing snapshot data....
    echo "Screens started"
    screen -ls



}

fix_filler(){
   instanadir="$backenddir/dev/scripts"
   instana_infra_dir="$backenddir/dev/infrastructure"
   echo "Docker containers running:"
   docker ps
   echo "Stoping elastic search"
   docker ps -q --filter "name=instana-elastic-ng" | grep -q . && docker stop instana-elastic-ng && docker rm -fv instana-elastic-ng
    while true;do echo -n .;sleep 1;done &
    sleep 25 # or do something else here
    kill $!; trap 'kill $!' SIGTERM
    echo done
    echo "Docker containers running:"
    docker ps
    echo "Restarting elastic search and configuring"
    cd $instana_infra_dir
    ./instana-elastic-ng
    screen -ls | grep filler | cut -d. -f1 | awk '{print $1}' | xargs kill
    echo "+++++++++ Starting filler component on screen  filler  +++++++++"
    screen -S filler -dm bash -c "$instanadir/start-component.sh filler"
    echo "+++++++++ app data Processor  +++++++++"
    screen -ls | grep appdata-processor | cut -d. -f1 | awk '{print $1}' | xargs kill
    screen -S appdata-processor -dm bash -c "$instanadir/start-component.sh appdata-processor"
    echo "+++++++++ Issue Tracker  +++++++++"
    screen -ls | grep issue-tracker | cut -d. -f1 | awk '{print $1}' | xargs kill
    screen -S issue-tracker -dm bash -c "$instanadir/start-component.sh issue-tracker"
    screen -ls | grep log-processor | cut -d. -f1 | awk '{print $1}' | xargs kill
    echo "+++++++++ Log processor  +++++++++"
    screen -S log-processor -dm bash -c "$instanadir/start-component.sh logging/log-processor"
    echo "+++++++++ Log writer  +++++++++"

    screen -ls | grep log-writer | cut -d. -f1 | awk '{print $1}' | xargs kill
    screen -S log-writer -dm bash -c "$instanadir/start-component.sh logging/log-writer"
    screen -ls | grep log-reader | cut -d. -f1 | awk '{print $1}' | xargs kill
    echo "+++++++++ Log reader  +++++++++"
    screen -S log-reader -dm bash -c "$instanadir/start-component.sh logging/log-reader"

    echo "+++++++++ Processor  +++++++++"
    screen -S processor -dm bash -c "$instanadir/start-component.sh processor"
    echo "Screens started"
    screen -ls
}

start_ui(){
   echo "Git pulling client ui"
   git_pull_client_ui
 if screen -list | grep -q "ui-client"; then
    echo "found existing screen ui-client killing it"
    while true;do echo -n .;sleep 1;done &
    sleep 10 # or do something else here
    kill $!; trap 'kill $!' SIGTERM
    echo done
      screen -ls | grep ui-client | cut -d. -f1 | awk '{print $1}' | xargs kill
   fi
   echo "starting screen"
   screen -S ui-client -m bash -c "cd $uiclientdir; yarn dev"

}


git_pull_backend(){
  cd $backenddir
  git pull
  cd ..
}

git_pull_client_ui(){
  cd $uiclientdir
  git pull
  cd ..
}

wait_progress(){
   while true;do echo -n .;sleep 1;done &
   sleep 45 # or do something else here
   kill $!; trap 'kill $!' SIGTERM
   echo done
}

parse_commandline "$@"



if [ -n "$_arg_all" ]; then
   echo "Git pulling backend"
   git_pull_backend
   echo "Git pulling client ui"
   git_pull_client_ui
   echo "Stopping all screens"
   stop_screen
   start_screen
   echo "Preparing to start UI"
   wait_progress
   start_ui
   exit 0
fi


if [ -n "$_arg_ui" ]; then
   start_ui
   exit 0
fi


if [ -n "$_arg_stop" ]; then
    stop_screen
    exit 0
fi

if [ -n "$_arg_run" ]; then
    start_screen
    exit 0
fi

if [ -n "$_arg_filler" ]; then
    fix_filler
    exit 0
fi
