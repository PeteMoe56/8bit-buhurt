#!/bin/bash
# TWO-PASS LOUDNORM.  Single-pass landed every track 1-1.5 LU under its target
# and squeezed the club-to-final spread to 1.9 LU, which is the whole escalation
# and not enough of it.
#
# NOTE: the measuring pass must NOT run at -v error.  loudnorm prints its JSON at
# INFO level, so silencing it hands pass two an empty measurement and ffmpeg
# fails with "Error initializing a simple filtergraph" — which names neither the
# filter nor the reason.
#
# FADES: A BAKED FADE IS WRONG FOR A LOOP, and the recipe's rule had to be read
# rather than followed.  `Audio._begin()` already starts a track at -80 dB and
# tweens it up, so a fade in the FILE fades twice on entry — and worse, a looping
# stream repeats the whole file, so a three-second fade at the top means the
# music dips every time the loop comes round.  The loops therefore ship flat with
# a 40 ms edge to kill the seam click, and the entrance lives in the engine where
# it can be interrupted.  The champion cue is a one-shot and keeps its fade-out.
loud () {
  NAME=$1; LUFS=$2; EXTRA=$3
  CHAIN="acompressor=threshold=-18dB:ratio=3:attack=8:release=180:makeup=2"
  M=$(ffmpeg -y -hide_banner -i ${NAME}_raw.wav -af "${CHAIN},loudnorm=I=${LUFS}:TP=-1.0:LRA=9:print_format=json" -f null - 2>&1 | python3 -c "
import sys,json,re
t=sys.stdin.read(); m=re.search(r'\{[^{}]*input_i[^{}]*\}', t, re.S)
d=json.loads(m.group(0)); print('%s|%s|%s|%s' % (d['input_i'],d['input_tp'],d['input_lra'],d['input_thresh']))")
  I=$(echo $M|cut -d'|' -f1); TP=$(echo $M|cut -d'|' -f2)
  LRA=$(echo $M|cut -d'|' -f3); TH=$(echo $M|cut -d'|' -f4)
  ffmpeg -y -v error -i ${NAME}_raw.wav -af \
"${CHAIN},loudnorm=I=${LUFS}:TP=-1.0:LRA=9:measured_I=${I}:measured_TP=${TP}:measured_LRA=${LRA}:measured_thresh=${TH}:linear=true${EXTRA}" \
    -ar 44100 ${NAME}_m.wav
  ffmpeg -y -v error -i ${NAME}_m.wav -c:a libvorbis -q:a 5 ${NAME}.ogg
  ffmpeg -y -v error -i ${NAME}_m.wav -c:a libmp3lame -b:a 96k ${NAME}.mp3
}
# NO EDGE FADE ON THE LOOPS. It went in to kill a click at the join and there was
# never a click to kill — the wrap discontinuity measures 0.0001 of peak, because
# the music starts on a downbeat from silence. What the 40 ms fade DID do was mute
# the attack of that downbeat, which showed up as a 157 dB "join step" on the club
# track: the loudest transient in the loop, made silent, once every sixty-nine
# seconds. The cure was the disease.
EDGE=""
## MENU IS THE QUIETEST THING IN THE GAME, on purpose: it is the first fifteen
## seconds and it should not announce itself. FIGHT is pulled back too — it plays
## under three rounds of gameplay, and a bout theme mixed like a feature is a
## bout theme the player turns off.
## The menu is the game's calling card, not its waiting room — it sits with the
## light tracks now rather than 2 LU below all of them.
loud menu     -17.5 "$EDGE"
loud club     -18.0 "$EDGE"
loud hosted   -16.5 "$EDGE"
loud fight    -17.0 "$EDGE"
loud cup      -16.0 "$EDGE"
loud final    -13.0 "$EDGE"
loud worlds   -14.5 "$EDGE"
DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 champion_raw.wav)
loud champion -13.5 ",afade=t=in:st=0:d=0.15,afade=t=out:st=$(python3 -c "print(max(0,$DUR-2.5))"):d=2.5"

# ---- one-shots ------------------------------------------------------------
# NO LOUDNESS NORMALISATION ON THESE. `loudnorm` targets an integrated loudness
# over time, and a 35 ms blip has almost no time — it would be dragged up by
# 20 dB to hit a number meant for a piece of music, and a button tap would be
# the loudest thing in the game. They are peak-normalised instead, at levels set
# by what they are FOR: a tap is background, a man going down is not.
sfx () {
  NAME=$1; PEAK=$2
  ffmpeg -y -v error -i /tmp/sfx/${NAME}_raw.wav \
    -af "volume=${PEAK}dB,alimiter=limit=0.95" -ar 44100 /tmp/sfx/${NAME}_m.wav
  ffmpeg -y -v error -i /tmp/sfx/${NAME}_m.wav -c:a libvorbis -q:a 5 /tmp/sfx/${NAME}.ogg
}
sfx tap      -13
sfx confirm  -10
sfx refuse   -10
sfx coin      -9
sfx down      -4
sfx clash     -8
sfx whistle   -6
sfx crowd    -11
