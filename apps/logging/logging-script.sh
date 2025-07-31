#!/bin/bash

# Capture any error
trap 'echo "Error occurred!"; exit 1' ERR

# Infinite loop
while true
do
    echo "Hello! I will wait for 5 seconds..."
    sleep 5
    echo "5 seconds have passed!"
done
