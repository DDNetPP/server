#!/bin/bash

while IFS='$\n' read -r line;
do
    echo "echo \"$(echo "$line" | sed 's/"/\\"/')\""
done

