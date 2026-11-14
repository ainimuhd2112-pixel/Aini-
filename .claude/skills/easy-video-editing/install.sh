#!/usr/bin/env bash
# Installs the video tools. Safe to run again. Never stops on errors.
PIP="pip install --break-system-packages -q"
apt-get update -q >/dev/null 2>&1
command -v ffmpeg >/dev/null || apt-get install -y -q ffmpeg >/dev/null 2>&1 || echo "ffmpeg install failed"
apt-get install -y -q fonts-montserrat >/dev/null 2>&1 || echo "font skipped"
$PIP faster-whisper "av<19" "opencv-contrib-python-headless<5" numpy || echo "python tools install failed"
python3 -c "from faster_whisper import WhisperModel; WhisperModel('small', device='cpu', compute_type='int8')" >/dev/null 2>&1 || echo "speech model skipped"
mkdir -p ~/easy-edit
echo "Video tools ready"
