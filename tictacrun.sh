#! /bin/bash
source `which my_do_cmd`

args=("$@")
nargs=$#
time_alloted=${args[0]}
command=${args[1]}
command_arguments=${args[@]:2}


sleep $time_alloted && touch "/tmp/pid_$$_killed" && kill  $$  &

while [ 1 -gt 0 ]
do
  $command $command_arguments
done
