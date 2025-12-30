#!/bin/bash

# Input, If/else
correct="no"
while [ "$correct" != "yes" ] && [ "$correct" != "y" ]; do
  read -p "Enter height (m) & weight (kg): " hei wei
  read -p "Height: $hei, Weight: $wei. Is your input correct? (yes/no) " correct
done
# N.B. must leave a "space" for []

bmi=$(echo "scale=2; $wei / ($hei^2)" | bc)
echo $bmi

if [ $bmi -gt 30.0 ]; then
  echo "Obesity"
elif [ $bmi -lt 18 ]; then
  echo "Underweight"
else
  echo "Normal"
fi

# if: Check file existence 
if [ -e /file/path/file.txt ] then
  echo "File exists"
fi

# Switch case
case $COUNTRY in
  Netherlands)
    echo -n "Dutch"
    ;;

  Germany | Austria)
    echo -n "German"
    ;;

  France | Belgium | Monaco)
    echo -n "French"
    ;;

  *)
    echo -n "Unknown"
    ;;
esac

# Loop
count=1
while [ $count -le 5 ]; do
  echo "while loop $count"
  ((count++)) # double brackets
done

for (( i=0; i<10; i+=3 )); do
  echo "for loop: C style: $i"
done

for i in {0..10}; do
  echo "for loop: {START..END} style: $i"
done

# Array
fruits=("apple" "banana" "cherry")
for fruit in "${fruits[@]}"; do
  echo $fruit
done
echo ${fruits[2]} # acc Arr. elem

# Var Scope
n=1
echo $n
func() {
    local n=30
    echo "\$n: $n is in the function block"
} 
func $n

set -x # Start Debug
funcArg() {
    local res=$(($1*$2+$3))
    echo $res
}
r=$(funcArg 4 5 6)
echo $r
set +x # End Debug



# -X: HTTP method
curl -X POST -H "Content-Type: application/json" \
    -d '{"name": "Fred", "status": "online"}' "https://www.example.com/"

# -d 'data' or -d @file


# Download
wget <url>

# Remote acc.
# ssh -i path/to/private/key user@host

# Cron job
# * * 29 2 * echo "This cron only runs every min, on 29 Feb"

which <cmd>
# locate executable file asso. w/ a given command name, e.g. ls, cronitor.
# for: delete undesirable CLI downloaded

