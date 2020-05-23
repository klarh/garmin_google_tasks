#! /usr/bin/env sh

set -e

function handle_sigint()
{
    for proc in `jobs -p`
    do
        kill $proc
    done
}

trap handle_sigint SIGINT

sdk/bin/connectiq&

sdk/bin/monkeydo $@ &

wait
