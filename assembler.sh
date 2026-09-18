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

elif [[ ! "$input" == "*.vsc" ]]; then
  echo -e "usage: input does not have the extension .vsc."
  exit 1

elif [ ! -s "$input" ]; then # checks if file empty by file size
  echo -e "usage: the file is empty -- no .bin file is produced"
  exit 1
fi

# TODO: Add pp cleaning for window and recheck size

# reading the file
line_num=0
quit_seen=0
instr_count=0
bytes=""
n_value=""

while IFS= read -r line; do
  line_num=$((line_num + 1))

  # Check that line 1 is either 0 or 2
  if [ $line_num -eq 1 ]; then
    n_value="$line"

    if [ "$n_value" != "0" ] && [ "n_value" != "2" ]; then
      echo -e "usage: line 1 of $input must be 0 or 2"
      exit 1
    fi
    continue
  fi

  # Case 1: line 1 == 0
  if [ "$n_value" -eq 0 ]; then
    if [ "$line_num" -eq 2 ] && [ "$line" = "QUIT,0,0" ]; then
      # TODO: create .bin file and exit out
      opcode=8
      quit_seen=1
      continue
    else
      echo -e "usage: a program with n_value=0 must contain exactly QUIT,0,0"
      exit 1
    fi

  fi

  #Case 2: line 2 == 2
  # Static Values
  if [ "$line_num" -eq 2 ] || [ "$line_num" -eq 3 ]; then

    # Making sure the entries are digits only
    if ! [[ "$line" =~ ^[0-9]+$ ]]; then
      echo -e "usage: static value on line $line_num must be a number"
      exit 1
    fi

    if [ "$line" -lt 0 ] || [ "$line" -gt 128 ]; then
      echo -e "usage: static value on line $line_num must be in be between 0 and 128 (inclusive)"
      exit 1
    fi

    hex_byte=$(printf '%02x' "$line")
    bytes="bytes $hex_byte"
    continue
  fi

  # Instructions

  # safety checks before parsing instructions
  if [ "$quit_seen" -eq 1 ]; then
    echo -e "usage: no instructions are allowed after QUIT,0,0"
    exit 1
  fi

  if [ "${#line}" -gt 11 ]; then
    echo -e "usage: instruction line is too long: $line"
    exit 1
  fi

  # splitting instructions into their components
  IFS=',' read -r ins reg mem <<< "$line"

  # check if the instruction was complete (no part empty)
  if [ -z "$ins" ] || [ -z "$reg" ] || [ -z "$mem" ]; then
    echo -e "usage: incomplete instruction: $line"
    exit 1
  fi



done < input


