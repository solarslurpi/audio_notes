import json
import os

import yaml


def format_time(seconds):
    """Convert seconds to HH:MM:SS format."""
    hours = int(seconds // 3600)
    minutes = int((seconds % 3600) // 60)
    seconds = int(seconds % 60)
    return f"{hours:02d}:{minutes:02d}:{seconds:02d}"


def _write_frontmatter(f, data, mp3_source):
    """Write metadata as Obsidian frontmatter to an open file."""
    if mp3_source:
     # MP3 metadata format
        frontmatter = {
            "title": data.get("title"),
            "duration": data.get("duration", 0),
            "audio_quality": data.get("audio_quality"),
            "sample_rate": data.get("sample_rate"),
            "file_path": data.get("file_path"),
            "upload_date": data.get("upload_date"),
        }
    else:
                # YouTube metadata format
        frontmatter = {
            "youtube_url": data.get("webpage_url", f'https://www.youtube.com/watch?v={data.get("id")}'),
            "title": data.get("title"),
            "tags": data.get("tags", []),
            "description": data.get("description", "").strip(),
            "uploader_id": data.get("uploader_id"),
            "channel": data.get("channel"),
            "upload_date": data.get("upload_date"),
            "duration": f"00:{data.get('duration', 0) // 60:02d}:{data.get('duration', 0) % 60:02d}",
        }

    f.write("---\n")
    yaml.dump(frontmatter, f, default_flow_style=False, allow_unicode=True, sort_keys=False, width=float("inf"), encoding=None)
    f.write("---\n")


def _write_srt_content(f, metadata, srt_content_dict):
    """Write content with chapters if available, otherwise write all text."""
    chunks_dict = srt_content_dict.get("chunks", [])
    if not chunks_dict and "speakers" in srt_content_dict:
        chunks_dict = [srt_content_dict]

    text_segments = [{"start_time": chunk["timestamp"][0], "end_time": chunk["timestamp"][1], "text": chunk["text"].strip()} for chunk in chunks_dict]

    if metadata.get("chapters"):
        current_segment_index = 0
        for chapter in metadata["chapters"]:
            # Replace untitled chapters with "Introduction"
            title = "Introduction" if "<Untitled Chapter" in chapter['title'] else chapter['title']

            f.write("\n")
            f.write(f"## {title}\n")
            f.write(f"{chapter['start_time']}s - {chapter['end_time']}s\n\n")

            chapter_text = []
            while current_segment_index < len(text_segments):
                segment = text_segments[current_segment_index]
                if segment["start_time"] is None and chapter == metadata["chapters"][-1]:
                    chapter_text.append(segment["text"])
                    current_segment_index += 1
                    continue

                if segment["start_time"] >= chapter["end_time"]:
                    break
                if segment["start_time"] >= chapter["start_time"]:
                    chapter_text.append(segment["text"])
                current_segment_index += 1

            # Add extra line break after the chapter text
            f.write(" ".join(chapter_text) + "\n\n\n")
    else:
        time_marker_interval = 300  # 5 minutes in seconds
        current_text = []
        last_marker = 0

        # Write initial timestamp
        marker_end = time_marker_interval
        f.write(f"{format_time(0)} - {format_time(marker_end)}\n\n")

        for segment in text_segments:
            if segment["start_time"] - last_marker >= time_marker_interval:
                if current_text:
                    f.write(" ".join(current_text) + "\n\n")
                    current_text = []

                marker_end = segment["start_time"] + time_marker_interval
                f.write(f"{format_time(segment['start_time'])} - {format_time(marker_end)}\n\n")
                last_marker = segment["start_time"]

            current_text.append(segment["text"])

        if current_text:
            f.write(" ".join(current_text) + "\n\n")


def create_obsidian_note(output_dir, basename, obsidian_dir, mp3_source=None):
    """
    Create an Obsidian note from a YouTube video.

    Args:
        output_dir (str): Directory containing the metadata and SRT files.
        basename (str): Base filename of the metadata (.info.json) and SRT (.json) files.
        obsidian_dir (str): Directory where the Obsidian note will be created.
        is_mp3 (bool): Whether the input is an mp3 file. This is to handle the metadata.

    Raises:
        FileNotFoundError: If metadata, SRT file or Obsidian directory is not found.
        NotADirectoryError: If Obsidian directory path exists but is not a directory.

    """
    def _create_mp3_metadata(mp3_path):
        """Create basic metadata for MP3 files."""
        import time
        from mutagen.mp3 import MP3
        try:
            audio = MP3(mp3_path)
            
            metadata = {
                "title": basename + ".mp3",
                "duration": format_time(audio.info.length),  # in seconds
                "audio_quality": f"{audio.info.bitrate // 1000}kbps",
                "sample_rate": f"{audio.info.sample_rate}Hz",
                "file_path": mp3_path,
                "upload_date": time.strftime("%Y%m%d"),  # Today's date
            }
        except Exception:
            raise
        
        return metadata
    if mp3_source:
        try:
            metadata = _create_mp3_metadata(mp3_source)
        except FileNotFoundError:
            raise FileNotFoundError(f"MP3 file not found: {mp3_source}")
        except Exception as e:
            raise Exception(f"Error creating metadata from MP3: {str(e)}")
    else:
        metadata_file = os.path.join(output_dir, f"{basename}.info.json")
        if not os.path.exists(metadata_file):
            raise FileNotFoundError(f"Metadata file not found : {metadata_file}")
        # Read metadata
        with open(metadata_file, encoding="utf-8") as f:
            metadata = json.load(f)
    srt_file = os.path.join(output_dir, f"{basename}.json")
    obsidian_note = os.path.join(obsidian_dir, f"{basename}.md")

    # Now check if files exist

    if not os.path.exists(srt_file):
        raise FileNotFoundError(f"SRT file not found : {srt_file}")

    # Verify obsidian directory exists
    if not os.path.exists(obsidian_dir):
        raise FileNotFoundError(f"Obsidian directory {obsidian_dir} does not exist")
    if not os.path.isdir(obsidian_dir):
        raise NotADirectoryError(f"'{obsidian_dir}' exists but is not a directory")


    # Read SRT
    with open(srt_file, encoding="utf-8") as f:
        srt_content = json.load(f)
    # Create Obsidian note

    # Create the full filepath using os.path.join to handle path separators correctly
    with open(obsidian_note, "w", encoding="utf-8") as f:
        _write_frontmatter(f, metadata, mp3_source)
        _write_srt_content(f, metadata, srt_content)
