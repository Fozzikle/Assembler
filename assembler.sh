#!/bin/bash

# Input Checks
if [ $# -eq 0 ]; then
  echo -e "usage: no argument is provided."
  exit 1

elif [ $# -gt 1 ]; then
  echo -e "usage: more than one argument are provided."
  exit 1
fi

# file checks
input=$1

if [ ! -f "$input" ]; then
  echo -e "usage: input is not a file or it does not exist."
  exit 1

elif [ ! "$input" == "*.vsc" ]; then
  echo -e "usage: input does not have the extension .vsc."
  exit 1

elif [ ! -s "$input" ]; then # checks if file empty by if file size
  echo -e "usage: the file is empty -- no .bin file is produced"
  exit 1
fi

