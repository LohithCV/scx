#!/usr/bin/env bash

layered_bin=${1:-../../../../target/release/scx_layered}
test_scripts=( "layer_node.bt" )

for test_script in "${test_scripts[@]}"; do
	sudo pkill -9 -f scx_layered
	sudo "${layered_bin}" --stats 1 f:numa.json -v &
	layered_pid=$!

	echo "layered pid ${layered_pid}"
	sleep 2

	stress-ng -c 2 -f 1 -t 30 &
	stress_pid=$!

	echo "stress-ng pid ${stress_pid}"
	sleep 1

	sudo "./${test_script}" "${stress_pid}"
	test_exit=$?

	pidof scx_layered && sudo pkill -9 -f scx_layered
	# always cleanup stress-ng
	sudo pkill -9 -f stress-ng

	if [ $test_exit -ne 0 ]; then
		echo "test script ${test_script} failed: ${test_exit}"
		exit $test_exit;
	fi
	echo "test script ${test_script} passed: ${test_exit}"
done
