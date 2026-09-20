#!/bin/bash

# Input Checks
if [ $# -eq 0 ]; then
  echo -e "usage: no argument is provided"
  exit 1

elif [ $# -gt 1 ]; then
  echo -e "usage: more than one arguments are provided"
  exit 1
fi

# file checks
input=$1

if [ -e "$input" ] && [ ! -f "$input" ]; then # arg 1 exists but is not a file
  echo -e "usage: input is not a file or it does not exist"
  exit 1

elif [[ ! "$input" == *.vsc ]]; then # checks for correct extension
  echo -e "usage: input does not have the extension .vsc"
  exit 1

elif [ ! -f "$input" ]; then # correct extension but missing file
  echo -e "usage: input is not a file or it does not exist"
  exit 1

elif [ ! -s "$input" ]; then # checks if file empty by file size
  echo -e "usage: the file is empty – no .bin file is produced"
  exit 1
fi

# Converts one decimal number into a 2-digit hex string.
to_hex() {
  printf '%02x' "$((10#$1))"
}

# reading the file
line_num=0
quit_seen=0
instr_count=0
dataArray=()
n_values=""

while IFS= read -r line || [ -n "$line" ]; do
  line="${line%$'\r'}" # strip Windows formatting
  line_num=$((line_num + 1))

  # Check that line 1 is either 0 or 2
  if [ "$line_num" -eq 1 ]; then
    n_values="$line"

    if [ "$n_values" != "0" ] && [ "$n_values" != "2" ]; then
      echo -e "usage: line 1 of $input must be 0 or 2"
      exit 1
    fi
    continue
  fi

  # blank lines after QUIT are harmless, so skip them
  if [ "$quit_seen" -eq 1 ] && [ -z "$line" ]; then
    continue
  fi

  # Case 1: line 1 == 0 (n_value of 0)
  if [ "$n_values" -eq 0 ]; then
    if [ "$line_num" -eq 2 ] && [ "$line" = "QUIT,0,0" ]; then
      opcode=8
      dataArray+=("$(to_hex $(( opcode * 4 )))" "00")
      quit_seen=1
      continue
    else
      echo -e "usage: a program with n_value=0 must contain exactly QUIT,0,0"
      exit 1
    fi

  fi

  # Case 2: line 1 == 2 (n_value of 2)
  # Static Values
  if [ "$line_num" -eq 2 ] || [ "$line_num" -eq 3 ]; then

    # Making sure the entries are digits only
    if ! [[ "$line" =~ ^[0-9]+$ ]]; then
      echo -e "usage: static value on line $line_num must be a number"
      exit 1
    fi

    if [ "${#line}" -gt 3 ] || [ "$((10#$line))" -ge 128 ]; then
      echo -e "usage: static value on line $line_num must be between 0 and 127 (inclusive)"
      exit 1
    fi

    dataArray+=("$(to_hex "$line")")
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

  # Assigning opcode to each instruction
  if [ "$ins" = "LOAD" ]; then
    opcode=1
  elif [ "$ins" = "STORE" ]; then
    opcode=2
  elif [ "$ins" = "ADD" ]; then
    opcode=3
  elif [ "$ins" = "SUB" ]; then
    opcode=4
  elif [ "$ins" = "QUIT" ]; then
    opcode=8
  elif [ "$ins" = "PRINT" ]; then
    opcode=9
  else
    echo -e "usage: unrecognised instruction: $ins"
    exit 1
  fi

  # Checking register input
  if ! [[ "$reg" =~ ^[0-9]+$ ]]; then
    echo -e "usage: register must be a number: $line"
    exit 1
  fi
  if (( 10#$reg > 3 )); then # again base 10 instead of 8
    echo -e "usage: register must be 0, 1, 2, or 3: $line"
    exit 1
  fi

  # Checking memory inputs
  if ! [[ "$mem" =~ ^[0-9]+$ ]] || (( 10#$mem > 255 )); then
    echo -e "usage: memory address must be a number from 0 to 255: $line"
    exit 1
  fi

  # QUIT format check
  if [ "$ins" = "QUIT" ] && { [ "$reg" != 0 ] || [ "$mem" != 0 ]; }; then
    echo -e "usage: QUIT must be written as QUIT,0,0: $line"
    exit 1
  fi

  # Encoding
  dataArray+=("$(to_hex $(( opcode * 4 + 10#$reg )))" "$(to_hex "$mem")")

  # Add instruction line to counter and check if total instructions exceed memory capacity (safety of 100 lines)
  instr_count=$((instr_count + 1))
  if [ "$ins" = "QUIT" ]; then
    quit_seen=1
  fi

  if [ "$instr_count" -gt 100 ]; then
    echo -e "usage: program exceeds the 100 instruction limit"
    exit 1
  fi

done < "$input"

# confirm .vsc contained a quit
if [ "$quit_seen" -ne 1 ]; then
  echo -e "usage: program does not terminate with QUIT,0,0"
  exit 1
fi

# determine type of program and its title
if [ "$n_values" -eq 0 ]; then
  title="It is a QUIT program"
else
  title="It is an ADD/SUB program"
fi

# Making and writing bytes to .bin file
output="${input%.vsc}.bin"
: > "$output" # making sure the file starts empty

for b in "${dataArray[@]}"; do
  printf "\\x$b" >> "$output"
done

# printing results to terminal
echo "$title"
echo "The content of the .bin file is"
for b in "${dataArray[@]}"; do
  echo "$b"
done

exit 0