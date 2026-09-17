#!/bin/bash

SAVE_DIR="$HOME/Videos/Recordings"
mkdir -p "$SAVE_DIR"
FILENAME="$SAVE_DIR/recording_$(date +'%Y-%m-%d_%H-%M-%S').mp4"

# Check if wf-recorder is currently running
if pgrep -x "wf-recorder" > /dev/null
then
    # Gracefully stop the recording to prevent file corruption
    pkill -INT -x wf-recorder
    
    # Send a success notification to SwayNC
    notify-send -a "Screen Recorder" -i video-x-generic "Recording Stopped" "Saved to: $FILENAME" -t 3000
else
    # Send a start notification to SwayNC
    notify-send -a "Screen Recorder" -i media-record "Recording Started" "Capturing full screen..." -t 3000
    
    # Start recording in the background
    # To record a selected region instead, replace the line below with: wf-recorder -g "$(slurp)" -f "$FILENAME" &
    wf-recorder -f "$FILENAME" &
fi
