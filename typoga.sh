#!/bin/bash

IFS=$'\n'

green=`tput setaf 2`
reset=`tput sgr0`

# File to read/write highScore. First line has highest score
hsFile='highScore.txt'
# Read Highest score
hscore=$(head -n 2 $hsFile | sed -n -e 2p | awk -F ':' '{print $2}')

MinChar2Score=80 # Minimum number of chars to get score

# Every time user reaches multiple of MinChar2Score 
# the Score is increased +10%: 1 -> 10%, 2 -> 20%
scFactor=0

score=0 # Saves the score. +1 if its a hit and -1 if its a miss
maxNChar=0 # Saves the total of hit characters
wordCount=-1 # Number of words completed
missedChar=-1 # Number of times you miss the character

# File to get list of words or phrases
fileW='phrases.txt'
#fileW='programing.txt'

# Read the file
words=(`cat $fileW`)

NUMBER_OF_LINES=$(wc -l $fileW | cut -f1 -d' ')
clear
echo ""
echo "Welcome to Typoga. Score to Beat: ${green}$hscore${reset}"
echo "Press '?' any time to finish game."
read -n 1 -s -p "Press any key to continue "
echo ""

################__GAME__################

startTime=`date +%s`
while true;do

    # Get random word every time
    rNum=$(( $RANDOM % $NUMBER_OF_LINES ))
    word=${words[rNum]}

    ((wordCount++))
    echo ": ${word}"
    echo -n ": "

    for i in `seq 0 $(( ${#word} -1 ))`; do

        # Check if user wants to end game.        
        while [ "$char" != "?" ];do
            read -n 1 -s char

            wordChar="${word:$i:1}"

            # Increase score by +10%
            if [ $(($maxNChar%$MinChar2Score)) -eq 0 ] && [ ! $maxNChar -eq 0 ]; then
                ((scFactor++))
            fi

            if [ "$char" == "$wordChar" ]; then
                printf "${green}${wordChar}${reset}"
                ((score++))
                ((maxNChar++))
                # Count words when dealing with phrases
                if [ "$char" == " " ]; then
                    ((wordCount++))
                fi
                break
            else
                # Count number of times missed
                ((missedChar++))
                #Remove score points for each missed character of the word
                if [ ! "$score" -eq 0 ] && [ "$char" != "?" ]; then
                     ((score--))
                fi
            fi
        done
    done

    if [ "$char" == "?" ]; then
        printf "\n\n"
        break
    fi
    echo ""
done
endTime=`date +%s`
runtimeSec=$((endTime-startTime))

#################__SCORE__################
# Only show score wit we reach at least once MinChar2Score and started playing it
if [ $scFactor -gt 0 ] && [ $maxNChar -gt 0 ]; then
    # Calculate Accuracy
    acc=$(echo "scale=2; acc = (${score}*100)/${maxNChar}; acc" | bc)
    echo "Accuracy: (${score}/${maxNChar}) = $acc %"

    # Calculate Words Per Minute
    wpm=$(echo "scale=2; spe = (${wordCount}*60)/${runtimeSec}; spe" | bc)
    echo "Speed: $wpm wpm"

    # Calculate Score
    sc=$(echo "scale=2; acc = (${score}*100)/${maxNChar};
    spe = (${wordCount}*60)/${runtimeSec};
    scf = ${scFactor}/10 + 1;
    var3 = acc*spe*scf;
    var3" | bc)

    # Store results into the file
    # timeSince19700101:score:acc:wpm:n_Words:n_missedCharacters:runTime
    result="$startTime:$sc:$acc:$wpm:$wordCount:$missedChar:$runtimeSec"
    echo $result >> $hsFile
    # Replace high score)
    if [ "$(echo "$sc>$hscore" | bc -l)" -eq 1 ]; then
        echo "Score: $sc ${green}New High Score!${reset}"
        sed -i "2s/.*/$result/" $hsFile
    else
        echo "Score: $sc "
    fi

else
    echo "You need to reach a least $MinChar2Score characters to get a score."
fi
