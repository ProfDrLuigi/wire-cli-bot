#!/bin/bash
#
#

####################################################
#### Switch desired function on or off (0 or 1).####
####################################################
user_join=0
user_leave=0
wordfilter=1
common_reply=1
####################################################

####################################################
######### Watch a directory for new files ##########
####################################################
watcher=0
watchdir="/PATH/TO/FILES"
####################################################

####################################################
################## openAI Token ####################
####################################################
openai_token="YOUR_TOKEN"
####################################################

####################################################
################# RSS Feed On/Off ##################
####################################################
rssfeed=0
####################################################

####################################################
### Let these users (login-name) control the bot ###
####################################################
admin_user="admin,luigi,peter"
####################################################

SELF=$(SELF=$(dirname "$0") && bash -c "cd \"$SELF\" && pwd")
cd "$SELF"

nick=$( cat wirebot.cmd | sed 's/-###.*//g' | xargs )
nick_low=$( echo "$nick" | tr '[:upper:]' '[:lower:]' )
command=$( cat wirebot.cmd | sed 's/.*-###-//g' | xargs )

################ Function Section ################

function print_msg {
  screen -S wirebot -p0 -X stuff "$say"^M
}

if [[ "$command" = "b:"* ]] || [[ "$command" = "B:"* ]]; then
  conversation=$( echo "$command" | sed 's/b:\ //g' )
  say=$( echo "$conversation" | openai complete -t "$openai_token" - )
  print_msg
  exit
fi

function rnd_answer {
  size=${#answ[@]}
  index=$(($RANDOM % $size))
  say=$( echo ${answ[$index]} )
  print_msg
}

function kill_screen {
  if [ -f watcher.pid ]; then
    rm watcher.pid
  fi
  if [ -f wirebot.stop ]; then
    rm wirebot.stop
  fi
  if [ -f wirebot.pid ]; then
    rm wirebot.pid
  fi
    if [ -f rss.pid ]; then
    rm rss.pid
  fi
  screen -XS wirebot quit
}

function watcher_def {
  inotifywait -m -e create,moved_to "$watchdir" | while read DIRECTORY EVENT FILE; do
    say=$( echo "$FILE" |sed -e 's/.*CREATE\ //g' -e 's/.*MOVED_TO\ //g' -e 's/.*ISDIR\ //g' )
    say=$( echo ":floppy_disk: New Stuff has arrived: $say" )
    print_msg
  done
}

function watcher_start {
  check=$( ps ax | grep -v grep | grep "inotifywait" | grep "$watchdir" )
  if [ "$check" = "" ]; then
    if ! [ -d "$watchdir" ]; then
      echo -e "The watch path \"$watchdir\" is not valid/available.\nPlease change it in wirebot.sh first and try again (./wirebotctl watch)."
      exit
    fi
    if screen -S wirebot -x -X screen -t watcher bash -c "bash "$SELF"/wirebot.sh watcher_def; exec bash"; then
      sleep 1
      ps ax | grep -v grep | grep "inotifywait*.* $watchdir" | sed 's/\ .*//g' | xargs > watcher.pid
      echo "Watcher started."
    else
      echo "Error on starting watcher. Make sure to run wirebot first! (./wirebotctl start)"
    fi
  fi
}

function watcher_stop {
  if ! [ -f watcher.pid ]; then
    echo "Watcher is not running!"
  else
    screen -S wirebot -p "watcher" -X kill
    rm watcher.pid
    echo "Watcher stopped."
  fi
}


function watcher_init {
  if [ "$watcher" = 1 ]; then
    if [ -d "$watchdir" ]; then
      watcher_start
    else
      echo -e "The watch path \"$watch=dir\" is not valid/available.\nPlease change it in wirebot.sh first and try again (./wirebotctl watch)."
    fi
  fi
}

function rssfeed_def {
  ./rss.sh
}

function rssfeed_start {
  check=$( ps ax | grep -v grep | grep "./rss.sh" )
  if [ "$check" = "" ]; then
    screen -S wirebot -x -X screen -t rss bash -c "bash "$SELF"/wirebot.sh rssfeed_def; exec bash" &
    sleep 2
    ps ax | grep -v grep | grep -v sleep | grep "rss.sh" | sed 's/\ .*//g' | xargs > rss.pid
    echo "RSS feed started."
  else
    echo "RSS feed is already running!"
    exit
  fi
}

function rssfeed_stop {
  if ! [ -f rss.pid ]; then
    echo "RSS feed is not running!"
  else
    screen -S wirebot -p "rss" -X kill
    rm rss.pid
    echo "RSS feed stopped."
  fi
}

function rssfeed_init {
  if [ "$rssfeed" = 1 ]; then
    rssfeed_start
  fi
}


################ Option Section ################

function user_join_on {
  sed -i '0,/.*user_join=.*/ s/.*user_join=.*/user_join=1/g' wirebot.sh
}

function user_join_off {
  sed -i '0,/.*user_join=.*/ s/.*user_join=.*/user_join=0/g' wirebot.sh
}

function user_leave_on {
  sed -i '0,/.*user_leave=.*/ s/.*user_leave=.*/user_leave=1/g' wirebot.sh
}

function user_leave_off {
  sed -i '0,/.*user_leave=.*/ s/.*user_leave=.*/user_leave=0/g' wirebot.sh
}

function wordfilter_on {
  sed -i '0,/.*wordfilter=.*/ s/.*wordfilter=.*/wordfilter=1/g' wirebot.sh
}

function wordfilter_off {
  sed -i '0,/.*wordfilter=.*/ s/.*wordfilter=.*/wordfilter=0/g' wirebot.sh
}

function common_reply_on {
  sed -i '0,/.*common_reply=.*/ s/.*common_reply=.*/common_reply=1/g' wirebot.sh
}

function common_reply_off {
  sed -i '0,/.*common_reply=.*/ s/.*common_reply=.*/common_reply=0/g' wirebot.sh
}

function rssfeed_on {
  sed -i '0,/.*rssfeed=.*/ s/.*rssfeed=.*/rssfeed=1/g' wirebot.sh
}

function rssfeed_off {
  sed -i '0,/.*rssfeed=.*/ s/.*rssfeed=.*/rssfeed=0/g' wirebot.sh
}

################ Phrase Section ################

#### User join server (user_join) ####
if [ $user_join = 1 ]; then
  if [[ "$command" == *" has joined" ]]; then
    nick=$( cat "$out_file" | sed -e 's/.*\]\ //g' -e 's/\ has\ joined//g' -e 's/;0m//g' | xargs )
    say="Hi $nick 😁"
    print_msg
  fi
fi

#### User leave server (user_leave) ####
if [ $user_leave = 1 ]; then
  if [[ "$command" == *" has left" ]]; then
    nick=$( cat "$out_file" | sed -e 's/.*\]\ //g' -e 's/\ has\ left//g' -e 's/;0m//g' | xargs )
    say="Bye $nick 😔"
    print_msg
  fi
fi

#### wordfilter (wordfilter)####
if [[ "$command" == *"Hey, why did you"* ]]; then
  exit
fi

if [ $wordfilter = 1 ]; then
  if [ "$command" = "shit" ] || [[ "$command" = *"fuck"* ]] || [ "$command" = "asshole" ] || [ "$command" = "ass" ] || [ "$command" = "dick" ]; then
    answ[0]="$nick, don't be rude please... 👎"
    answ[1]="Very impolite! 😠"
    answ[2]="Hey, why did you say \"$command\" ? 😧 😔"
    rnd_answer
    exit
  fi
fi

#### Common (common_reply) ####
if [ $common_reply = 1 ]; then
  if [[ "$command" = "wired" ]]; then
    answ[0]="Uh? What's "Wired" $nick? ‍😖"
    answ[1]="Ooooh, Wired! The magazine ? 😟"
    rnd_answer
  fi
  if [[ "$command" = "shut up bot" ]] ; then
    answ[0]="Moooooo 😟"
    answ[1]="Oh no 😟"
    answ[2]="Nooooo 😥"
    rnd_answer
    exit
  fi
  if [[ "$command" = "bot" ]]; then
    answ[0]="Do you talked to me $nick?"
    answ[1]="Bot? What's a bot?"
    answ[2]="Bots are silly programs. 🙈"
    answ[3]="…"
    answ[4]="hides!"
    answ[5]="runs!"
    rnd_answer
  fi
  if [ "$command" = "hello" ] || [ "$command" = "hey" ] || [ "$command" = "hi" ]; then
    answ[0]="Hey $nick. 😁"
    answ[1]="Hello $nick. 👋"
    answ[2]="Hi $nick. 😃"
    answ[3]="Yo $nick. 😊"
    answ[4]="Yo man ... whazzup? ✌️"
    rnd_answer
  fi
fi

################ Admin Section ################

if [[ "$command" = \!* ]]; then
  login=""
  say="/clear"
  print_msg
  say="/info \"$nick\""
  print_msg
  sleep 0.5
  screen -S wirebot -p0 -X hardcopy "$SELF"/wirebot.login
  login=$( cat wirebot.login | grep -v grep | grep "Login:" | sed 's/.*Login:\ //g' | xargs )
  rm wirebot.login
  
  if [[ "$login" != "" ]]; then
    if [[ "$admin_user" == *"$login"* ]]; then
      allowed=1
    else
      allowed=0
      say="🚫 You are not allowed to do this $nick 🚫"
      print_msg
      exit
    fi
  fi
fi

if [ "$allowed" = 1 ]; then
  if [ "$command" = "!" ]; then
    say="⛔ This command is not valid. ⛔"
    print_msg
  fi
  if [ "$command" = "!sleep" ]; then
    answ[0]="💤"
    answ[1]=":sleeping: … Time for a nap."
    rnd_answer
    say="/afk"
    print_msg
  fi
  if [ "$command" = "!start" ]; then
    answ[0]="Yes, my lord."
    answ[1]="I need more blood.👺"
    answ[2]="Ready to serve.👽"
    rnd_answer
  fi
  if [ "$command" = "!stop" ]; then
    answ[0]="Ping me when you need me. 🙂"
    answ[1]="I jump ❗"
    rnd_answer
    say="/afk"
    print_msg
    touch wirebot.stop
  fi
  if [ "$command" = "!userjoin on" ]; then
    user_join_on
  fi
  if [ "$command" = "!userjoin off" ]; then
    user_join_off
  fi  
  if [ "$command" = "!userleave on" ]; then
    user_leave_on
  fi
  if [ "$command" = "!userleave off" ]; then
    user_leave_off
  fi 
  fi
    if [ "$command" = "!kill_screen" ]; then
    say="Cya."
    kill_screen
  fi

  if [ -f wirebot.stop ]; then
    if [ "$command" = "!start" ]; then
          rm wirebot.stop
    elif [ "$command" = "!stop" ]; then
      say="/afk"
      print_msg
      exit
    else
      exit
    fi
  elif [ ! -f wirebot.stop ]; then
    if [ "$command" = "!start" ]; then
          exit
    fi
  fi

  if [[ "$command" == *"Using timestamp"* ]]; then
    if [ -f wirebot.stop ]; then
      rm wirebot.stop
  fi
 
fi

$1
