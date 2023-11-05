#!/bin/sh
MENU_PIXEL_SIZE=60
TITLE_PIXEL_SIZE=34
BORDER_PIXEL_SIZE=8

#HOST=localhost
#RTSP_PORT=8554
#API_PORT=9997

HOST=52.62.160.219
RTSP_PORT=30554
WEBRTC_PORT=30889
API_PORT=30997

POSTFIX="-HPE-RH"
POSTFIX="/"
PREFIX="${WEBRTC_PORT}/"

X_TOP_BROWSER=0
Y_TOP_BROWSER=0
X_SIZE_BROWSER=$(( 1920 - $BORDER_PIXEL_SIZE ))
Y_SIZE_BROWSER=$((1440 - $TITLE_PIXEL_SIZE  - $MENU_PIXEL_SIZE))
#CHROME_TITLE="Wikipedia, the free encyclopedia - Google Chrome"
#CHROME_URL="https://en.wikipedia.org/wiki/Main_Page"
#CHROME_TITLE="Topology - Red Hat OpenShift - Google Chrome"
CHROME_TITLE="Red Hat OpenShift - Google Chrome"
CHROME_URL="https://console-openshift-console.apps.hub.sandbox2868.opentlc.com/topology/ns/edge?view=graph"

PI_BEFORE_NAME=pi
PI_AFTER_NAME=pi-yolo
X_SIZE_PI=$(( 960 - 8 ))
Y_SIZE_PI=$(( 720 - 6 ))
X_TOP_PI_BEFORE=0
Y_TOP_PI_BEFORE=$(( $Y_SIZE_BROWSER + $TITLE_PIXEL_SIZE))
X_TOP_PI_AFTER=$(( $X_SIZE_PI + $BORDER_PIXEL_SIZE ))
Y_TOP_PI_AFTER=$Y_TOP_PI_BEFORE

X_TILE_SIZE=896
Y_TILE_SIZE=672

X_TILE_SMALL_SIZE=576
Y_TILE_SMALL_SIZE=432


#Test setup:
#./start-mediamtx-podman.sh
#ffmpeg -f v4l2 -framerate 30 -video_size 640x480 -i /dev/video0 -vcodec h264 -bf 0  -preset ultrafast -force_key_frames "expr:gte(t,n_forced*1)" -f rtsp -rtsp_transport tcp rtsp://localhost:8554/test
#ffmpeg -i rtsp://localhost:8554/test -preset ultrafast -vcodec libx264 -bf 0 -force_key_frames "expr:gte(t,n_forced*1)" -f rtsp rtsp://localhost:8554/test2
#ffmpeg -i rtsp://localhost:8554/test -preset ultrafast -vcodec libx264 -bf 0 -force_key_frames "expr:gte(t,n_forced*1)" -f rtsp rtsp://localhost:8554/test3

#

function get_window_id {
    #WINID=$(xdotool search --onlyvisible --name "$1-$POSTFIX")
    WINID=$(xdotool search --name "$PREFIX$1$POSTFIX")
    echo $WINID
}

function create_ffplay {
    # add -noborder?
    THEPID=$(ps aux | grep ffplay | grep " $1-$POSTFIX " | awk '{print $2}')
    if [ "$THEPID" == "" ]; then
	echo "no process found, going to create the window"
	#ffplay -autoexit -flags low_delay -fflags nobuffer -flags low_delay -max_delay 0 -framedrop -strict experimental -sync ext -window_title "$1-$POSTFIX" rtsp://$HOST:$RTSP_PORT/$1 >& /dev/null &
	#ffplay -autoexit -flags low_delay -fflags nobuffer -flags low_delay -max_delay 0 -framedrop  -window_title "$1-$POSTFIX" rtsp://$HOST:$RTSP_PORT/$1 >& /dev/null &
	ffplay -autoexit -flags low_delay -fflags nobuffer -framedrop -window_title "$1-$POSTFIX" rtsp://$HOST:$RTSP_PORT/$1 >& /dev/null &
	#google-chrome --new-window "https://52.62.160.219:30889/pi-yolo" --user-data-dir=/tmp/chrome/
    else
	echo "process $THEPID found, the window is probably still being created, skipping the creation of the window"
    fi
}

function prune_webrtc {

    STREAM_LIST=$(curl -s $HOST:$API_PORT/v2/paths/list | jq .items[].name -r | sort)
    ID_LIST=$(xdotool search --name "$HOST:$WEBRTC_PORT")
    echo "$STREAM_LIST"
    for i in $ID_LIST; do
	NAME=$(xdotool getwindowname $i)
	echo "$i -> $NAME"
	SHORT=$(echo $NAME | awk -F "$WEBRTC_PORT/" '{print $2}' | awk -F "/" '{print $1}')
	echo "SHORT: $SHORT"
	echo "$STREAM_LIST" | grep "^$SHORT$"
	#echo "$STREAM_LIST" | grep "$SHORT"
	if [ "$?" == "0" ]; then
	    echo "NOT pruning $NAME"
	else
	    echo "pruning $NAME"
	    xdotool windowclose $i
	    xdotool windowquit $i
	fi
    done

}

function create_webrtc {
    ps aux | grep chrome | grep "$WEBRTC_PORT/$1"
    THEPID=$(ps aux | grep chrome | grep "$WEBRTC_PORT/$1" | awk '{print $2}')
    if [ "$THEPID" == "" ]; then
	echo "no process found, going to create the webrtc window"
	google-chrome --new-window "https://$HOST:$WEBRTC_PORT/$1" --user-data-dir=/tmp/chrome/  >& /dev/null &
    else
	echo "process $THEPID found, the window is probably still being created, skipping the creation of the window"
    fi

}

function get_browser_id {
    #WINID=$(xdotool search --onlyvisible --name ".*Red Hat OpenShift - Google Chrome")
    WINID=$(xdotool search --onlyvisible --name "$CHROME_TITLE")
    echo $WINID
}

function create_browser {
    echo "going to create chrome windows"
    google-chrome --new-window "$CHROME_URL"
    #sleep 0.5

    #xdotool windowminimize $(get_browser_id)

}

function place_browser {
    xdotool windowsize $1 $X_SIZE_BROWSER $Y_SIZE_BROWSER
    xdotool windowmove $1 $X_TOP_BROWSER $Y_TOP_BROWSER
}

function place_pi_before {
    xdotool windowsize $1 $X_SIZE_PI $Y_SIZE_PI
    xdotool windowmove $1 $X_TOP_PI_BEFORE $Y_TOP_PI_BEFORE
}

function place_pi_after {
    xdotool windowsize $1 $X_SIZE_PI $Y_SIZE_PI
    xdotool windowmove $1 $X_TOP_PI_AFTER $Y_TOP_PI_AFTER
}


function main_browser {
    THEWINID=$(get_browser_id "${CHROME_TITLE}")
    #echo "${CHROME_TITLE} -> $THEWINID"
    if [ "$THEWINID" == "" ]; then
	echo "no  browser, creating"
	create_browser
	sleep 0.1
    fi
    THEWINID=$(get_browser_id "${CHROME_TITLE}")
    if [ "$THEWINID" == "" ]; then
	continue;
    else
	place_browser $THEWINID
    fi
}


function place_yolo {
    xdotool windowsize $1 $4 $5
    xdotool windowmove $1 $2 $3
}

function normal_tile {
    YM=$(( $2 / 2 ))
    Y=$(( $YM * $(( $Y_TILE_SIZE + $TITLE_PIXEL_SIZE ))))
    XM=$(( $2 % 2 ))
    X=$(( 1920 + $XM * $(( $X_TILE_SIZE + $BORDER_PIXEL_SIZE))))
    place_yolo $1 $X $Y $X_TILE_SIZE $Y_TILE_SIZE
}

function small_tile {
    YM=$(( $2 / 3 ))
    Y=$(( $YM * $(( $Y_TILE_SMALL_SIZE + $TITLE_PIXEL_SIZE ))))
    XM=$(( $2 % 3 ))
    X=$(( 1920 + $XM * $(( $X_TILE_SMALL_SIZE + $BORDER_PIXEL_SIZE))))
    place_yolo $1 $X $Y $X_TILE_SMALL_SIZE $Y_TILE_SMALL_SIZE
}


function main_ffplay {
    THEJSON=$(curl -s $HOST:$API_PORT/v2/paths/list | jq .)
    TOTAL_COUNT=$(echo $THEJSON | jq .itemCount)
    NAME_LIST=$(echo $THEJSON | jq .items[].name -r | sort)
    count=0

    NO_PI_COUNT=$TOTAL_COUNT
    for i in $NAME_LIST; do
	if  [ "$i" == "$PI_BEFORE_NAME" ] || [ "$i" == "$PI_AFTER_NAME" ]; then
	    NO_PI_COUNT=$(($NO_PI_COUNT - 1))
	fi
    done

    #echo "TOTAL COUNT = $TOTAL_COUNT and NO_PI_COUNT=$NO_PI_COUNT"

    for i in $NAME_LIST; do
	echo $i | grep '\-yolo$' >/dev/null
	if [ "$?" == "0" ]; then
	    #echo "It's a yolo windows"
	    :
	else
	    #echo "it's not a yolo window"
	    if  [ "$i" == "$PI_BEFORE_NAME" ] || [ "$i" == "$PI_AFTER_NAME" ]; then
		:
		#echo "it's a pi window"
	    else
		#echo "it's not a pi window, continue"
		continue
	    fi
	fi

	THEWINID=$(get_window_id $i)
	#echo "$i -> $THEWINID ($count)"
	if [ "$THEWINID" == "" ]; then
	    echo "no window, creating"
	    #create_ffplay $i
	    create_webrtc $i
	    sleep 0.1
	fi
	THEWINID=$(get_window_id $i)
	if [ "$THEWINID" == "" ]; then
	    continue;
	else
	    if [ "$i" == "$PI_BEFORE_NAME" ]; then
		place_pi_before $THEWINID
	    elif [ "$i" == "$PI_AFTER_NAME" ]; then
		place_pi_after $THEWINID
	    else
		if [ $NO_PI_COUNT -lt 7 ]; then
		    normal_tile $THEWINID $count
		else
		    small_tile $THEWINID $count
		fi
		count=$((count + 1))
	    fi
	fi
    done
}

while true; do main_browser; main_ffplay; sleep 0.1; prune_webrtc; done

exit



#google-chrome --new-window https://console-openshift-console.apps.test3.cszevaco.com/topology/ns/edge?view=graph

function get_browser_id {
    WINID=$(xdotool search --onlyvisible --name ".*Red Hat OpenShift - Google Chrome")
}
function get_pi_id {
    WINID=$(xdotool search --onlyvisible --name ".*Red Hat OpenShift")
}


function fix_window {
    WINID=$(xdotool search --onlyvisible --name $1)
    if [ "$WINID" == "" ]
    then
	:
	#echo "nothing found for $1"
    else
	#echo "Found $1 -> $WINID"
	xdotool set_desktop_for_window $WINID 4
	xdotool windowsize $WINID $2 $3
	xdotool windowmove $WINID $4 $5
    fi
}

while true; do
    fix_window "pi-v1" 512 384 0 660
    fix_window "pi-v2" 512 384 518 660
    fix_window "pi-v3" 640 480 1036 560
    sleep 0.3
done


