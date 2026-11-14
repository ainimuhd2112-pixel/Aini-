---
name: easy-video-editing
description: Simple video editing for reels and short videos with ffmpeg, faster-whisper and OpenCV. Use when the person uploads a video or asks to transcribe it, add captions, make it vertical / follow the face, cut silent parts or pauses, trim, join clips, add background music, speed up, shrink for WhatsApp, or make a cover photo. Handles English and Malay speech.
---

# Easy Video Editing

The person is not technical. Talk in plain, simple words and don't show commands unless they ask.

## 0. Make sure the tools are ready (do this first, every session)

```bash
SK="$(git rev-parse --show-toplevel 2>/dev/null)/.claude/skills/easy-video-editing"
mkdir -p ~/easy-edit && cp "$SK"/scripts/*.py ~/easy-edit/
python3 -c "import faster_whisper, cv2" 2>/dev/null && command -v ffmpeg >/dev/null && echo READY || bash "$SK/install.sh"
```

If the speech model can't download, tell the person: "Speech-to-text needs the Hugging Face websites allowed in your cloud settings." Everything else still works.

## 1. Where files are

- Uploads in Claude Code (cloud): `/root/.claude/uploads/<session-id>/` (in claude.ai chat: `/mnt/user-data/uploads/`). Use `ls` to find them.
- Work on a copy; never change the original. Name results clearly (`reel-captions.mp4`).
- Put finished videos in the project folder (or scratchpad) and send them to the person with SendUserFile.
- Reels are 1080x1920 (9:16), H.264 + AAC, `-pix_fmt yuv420p -movflags +faststart`.

## 2. Check your own work after every edit

```bash
ffprobe -v error -show_entries format=duration:stream=width,height -of csv=p=0 out.mp4
ffmpeg -y -i out.mp4 -vf "fps=6/DUR,scale=270:-1,tile=6x1" -frames:v 1 sheet.jpg   # DUR = length in seconds
```
Look at `sheet.jpg` with Read before saying it's done. Remind the person to watch the video before posting.

## 3. Recipes

**Transcribe / captions file**
```bash
python3 ~/easy-edit/transcribe.py in.mp4 --lang en
python3 ~/easy-edit/transcribe.py in.mp4 --lang ms --model medium --prompt "names, brand words"   # Malay
```
Makes `in.srt` and `in_words.json`. Show the person the words. Fix wrong names in the .srt by hand.
(`medium` is a bigger download the first time.)

**Pop-up captions burned in** (video must already be 1080x1920)
```bash
python3 ~/easy-edit/popcaps.py in.srt caps.ass --accent "FREE,WEIGHT"
ffmpeg -i in.mp4 -vf "ass=caps.ass" -c:v libx264 -crf 18 -pix_fmt yuv420p -c:a copy -movflags +faststart out.mp4
```

**Plain captions burned in** (any size)
```bash
ffmpeg -i in.mp4 -vf "subtitles=in.srt:force_style='FontName=Montserrat,FontSize=14,Bold=1,Outline=2,MarginV=60'" -c:v libx264 -crf 18 -pix_fmt yuv420p -c:a copy out.mp4
```

**Vertical reel that follows the face** (~3 s of work per 1 s of video)
```bash
python3 ~/easy-edit/facetrack.py in.mp4 out.mp4      # calmer: --smooth 0.04, faster: --every 5
```
Follows the biggest face. Already-vertical videos stay full-frame (just scaled to 1080x1920).

**Cut the pauses**
```bash
python3 ~/easy-edit/cutpauses.py in.mp4 out.mp4 --min 0.35
```

**Trim** (keep 0:05 to 0:20)
```bash
ffmpeg -ss 00:00:05 -to 00:00:20 -i in.mp4 -c:v libx264 -crf 18 -pix_fmt yuv420p -c:a aac out.mp4
```

**Join clips** (re-encodes, so clips from different phones still join)
```bash
ffmpeg -i a.mp4 -i b.mp4 -filter_complex "[0:v]scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2,setsar=1,fps=30[v0];[1:v]scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2,setsar=1,fps=30[v1];[0:a]aresample=48000[a0];[1:a]aresample=48000[a1];[v0][a0][v1][a1]concat=n=2:v=1:a=1[v][a]" -map "[v]" -map "[a]" -c:v libx264 -crf 18 -pix_fmt yuv420p -c:a aac out.mp4
```
More clips: add inputs and `[v2][a2]`, set `n=`. A clip with no sound needs a silent track first (`-f lavfi -i anullsrc=r=48000:cl=stereo` + `-shortest`).

**9:16 with blurred background** (for landscape videos)
```bash
ffmpeg -i in.mp4 -filter_complex "[0]scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,boxblur=20[bg];[0]scale=1080:-2[fg];[bg][fg]overlay=(W-w)/2:(H-h)/2" -c:v libx264 -crf 18 -pix_fmt yuv420p -c:a copy out.mp4
```

**Music under the voice** (music ~15%, fades out over the last 2 s)
```bash
ffmpeg -i in.mp4 -i music.mp3 -filter_complex "[1:a]volume=0.15,afade=t=out:st=DUR-2:d=2[m];[0:a][m]amix=inputs=2:duration=first:normalize=0[a]" -map 0:v -map "[a]" -c:v copy -c:a aac out.mp4
```
Replace `DUR-2` with the number (video length minus 2). `normalize=0` keeps the voice at full volume.
Only use music the person owns or that is royalty-free. Never put song lyrics on screen.

**Speed up 1.2x**
```bash
ffmpeg -i in.mp4 -filter_complex "[0:v]setpts=PTS/1.2[v];[0:a]atempo=1.2[a]" -map "[v]" -map "[a]" -c:v libx264 -crf 18 -pix_fmt yuv420p out.mp4
```

**Smaller for WhatsApp**
```bash
ffmpeg -i in.mp4 -vf "scale=-2:'min(1280,ih)'" -c:v libx264 -crf 28 -preset slow -pix_fmt yuv420p -c:a aac -b:a 96k -movflags +faststart small.mp4
```

**Cover photo**
```bash
ffmpeg -ss 00:00:03 -i in.mp4 -frames:v 1 -q:v 2 cover.jpg
```

## Rules
- Simple words. No commands unless asked.
- Keep the original untouched.
- Captions sit in the lower middle so TikTok/Instagram buttons don't cover them.
- If something fails, say what failed in one line and try the next simplest way.
