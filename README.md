# 🎵 Audio to Obsidian
Two bash scripts:
- yt2o.sh - YouTube to Obsidian Converter
- mp32o.sh - MP3 to Obsidian Converter
can turn an audio file into a structured Obsidian note in which the frontmatter, tags, and chapters as well as the transcribed text are included.

I am running this on a Windows machine, so I am using WSL to run the scripts.

## ✨ Features
- Downloads YouTube videos or Shorts
- Extracts audio in MP3 format
- Transcribes audio using Insanely-Fast-Whisper
- Creates structured Obsidian notes with:
  - Video metadata in YAML frontmatter (title, URL, channel, duration, etc.)
  - Chapter-based organization (if present in original video)
  - 5-minute segments for chapterless videos (improves Obsidian's text handling)
- Supports custom output directories
- Handles cleanup of temporary files

## 📋 Prerequisites
- Bash shell
- `yt-dlp`
- `ffmpeg`
- `pipx` Insanely-Fast-Whisper installed
- `pipx` `create-obsidian-note` (custom Python script that builds the Obsidian note. Currently, it is installed via `pipx install -e .)

## 🚀 Usage
```
./yt2o.sh [OPTIONS] <YouTube_URL>
./yt2o.sh -d ~/Documents/YouTube_Notes -c https://www.youtube.com/watch?v=dQw4w9WgXcQ
- d: directory for output
- c: clean up temporary files after processing
```
## 🛠️ Software
### 📥 1. yt-dlp
I used `yt-dlp` to convert the YouTube video to mp3 as well as download the metadata associated with the video. The metadata is a rich source of information, particularly when chapters are included. Chapters break up the video and provide topic information.  These are preserved during the transcript.  If the metdata does not include chapter information, the transcript is broken into 5 minute time chunks.  I found if I just translated the text and wrote it out, Obsidian choked because there was no new line.

The `audio_quality` and `post_processing` attributes have been chosen to be the best for transcription based on the kind of audio models like `whisper` are trained on.  I got this information from a Deeplearning.ai course. Although I forget which one. Other postprocessing options include one to retrieve the metadata from the video. They came about after much trial and error.

The output of `yt-dlp` includes the .mp3 file an a `.info.json` file containing the metadata.  The metadata file is passed in as an argument to the third piece of software, `create-obsidian-note`, discussed below.The `insanely-fast-whisper` software takes in the mp3 file `yt-dlp`.

### ⚡ 2. insanely-fast-whisper
I installed [`insanely-fast-whisper`](https://github.com/Vaibhavs10/insanely-fast-whisper) using `pipx` so that the translation software is globally available within a `wsl` terminal.  I think I was able to get the fast attention 2 code working. I left it to compile overnight.  It was taking many hours to complete.  When it finished, there wasn't an error but the `wsl` terminal was shut.  When I do use it, I get an error: `You are attempting to use Flash Attention 2.0 with a model not initialized on GPU. Make sure to move the model to GPU after initializing it on CPU with model.to('cuda').` I left an issue on GitHub.

Prior to using `insanely-fast-whisper`, I had used both `faster-whisper` and the Hugging Face APIs to the `whisper` models. `insanely-fast-whisper` seemed like a good alternative.  Verdict is still out if it really is insanely fast given the challenges of installing `flash-attention` on Windows.

### ✍️ 3. create_obsidian_note
The third piece of software takes in the metadata file (`.info.json`) and the transcription (`.json`) created by `insanely-fast-whisper` and creates an Obsidian note where many of the metadata fields are transferred as YAML frontmatter in the note.  The rest is the content, broken into chapter if chapter information was contained in within the metadata.

I created a `pipx` install for `create-obsidian-note` so that it is globally available within the `wsl` environment.

## Python files
### create_obsidian_note
`create_obsidian_note` is a Python package directory.  `pipx install -e .` modifies the pyproject.toml file by setting   `cli.py` as its main entry point. `pipx` also creates a proper Python package directory structure that includes `__init__.py` and `__main__.py` files.

### cli.py
This is the command line interface using the `click` library for the `create-obsidian-note` Python script.

#### Three arguments
It takes three arguments:

- `output_dir` (required): Directory containing transcription file.
  - Type: Path
  - Validation: Must be a valid filesystem path
- `basename` (required): Base name for the metadata (`.info.json`) and transcription (`.json`) files.
  - Type: String
- `obsidian_dir` (optional): Directory for saving Obsidian notes.
  - Type: Path
  - Default: Uses OBSIDIAN_DIR constant

#### One Option
- `--debug`: Optional flag to print debug information. When enabled, it prints:
  - Output directory path
  - Base name
  - Obsidian directory path

### note_creator.py
The function `create_obsidian_note` in `note_creator.py` takes in the metadata file (`.info.json`) and the transcription (`.json`) created by `insanely-fast-whisper` and creates an Obsidian note where many of the metadata fields are transferred as YAML frontmatter in the note.  The rest is the content, broken into chapter if chapter information was contained in within the metadata. If chapter information was not provided in the metadata, the text is broken into 5 minute time chunks.  Obsidian does not handle long chunks of text that does not have new lines.

## ⚠️ Troubleshooting

- If the script fails to run, ensure it has execute permissions: `chmod +x yt2o.sh`
- Check that all required tools (`yt-dlp`, `ffmpeg`, etc.) are installed and in your PATH

## ⚖️ License

MIT License

Copyright (c) 2024 Margaret Johnson

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## 📝 TLDR

### 💻 Git Bash vs WSL vs PowerShell
Git Bash: This is a Windows application that emulates a bash-like environment. It uses MinGW (Minimalist GNU for Windows) to provide Unix tools on Windows. The script works here because it's designed to mimic a Unix-like environment.  I use this in my VS Code terminal.
### 🐧 WSL (Windows Subsystem for Linux)
This is a full Linux distribution running on Windows. It has its own file system, environment variables, and installed packages, separate from your Windows environment.
### 🔧 PowerShell
This is a native Windows shell with its own syntax and commands, very different from bash...._So confusing!_
### ⌨️ Command Prompt (CMD)
CMD is the traditional command-line interpreter for Windows. It has been part of Windows since the early days and is based on MS-DOS commands.
Key characteristics:
- Uses batch commands and .bat scripts
- Limited functionality compared to PowerShell or WSL
- Primarily used for basic Windows administration tasks
