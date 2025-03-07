#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

INPUT_NAME() {
  echo "Enter your username:"
  read NAME
  n=${#NAME}

  # Ensure username is between 1-22 characters
  if [[ $n -gt 22 ]] || [[ $n -eq 0 ]]
  then
    INPUT_NAME
  else
    USER_INFO=$($PSQL "SELECT user_id, games_played FROM users WHERE username='$NAME';")
    
    if [[ -z $USER_INFO ]]
    then
      # New user
      echo "Welcome, $NAME! It looks like this is your first time here."
      $PSQL "INSERT INTO users(username, games_played) VALUES('$NAME', 0);"
      USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$NAME';")
      GAME_PLAYED=0
      BEST_GAME="N/A"
    else
      # Existing user
      IFS="|" read USER_ID GAME_PLAYED <<< "$USER_INFO"
      BEST_GAME=$($PSQL "SELECT MIN(best_guess) FROM games WHERE user_id=$USER_ID;")
      if [[ -z $BEST_GAME ]]; then BEST_GAME="N/A"; fi
      echo "Welcome back, $NAME! You have played $GAME_PLAYED games, and your best game took $BEST_GAME guesses."
    fi

    PLAY_GAME $USER_ID $NAME
  fi
}

PLAY_GAME() {
  USER_ID=$1
  USERNAME=$2
  SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
  NUMBER_OF_GUESSES=0

  echo "Guess the secret number between 1 and 1000:"
  
  while true
  do
    read GUESS
    if [[ ! $GUESS =~ ^[0-9]+$ ]]
    then
      echo "That is not an integer, guess again:"
      continue
    fi

    ((NUMBER_OF_GUESSES++))

    if [[ $GUESS -lt $SECRET_NUMBER ]]; then
      echo "It's higher than that, guess again:"
    elif [[ $GUESS -gt $SECRET_NUMBER ]]; then
      echo "It's lower than that, guess again:"
    else
      echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
      
      # Update user stats
      ((GAME_PLAYED++))
      $PSQL "UPDATE users SET games_played=$GAME_PLAYED WHERE user_id=$USER_ID;"
      $PSQL "INSERT INTO games(user_id, best_guess) VALUES($USER_ID, $NUMBER_OF_GUESSES);"
      break
    fi
  done
}

INPUT_NAME
