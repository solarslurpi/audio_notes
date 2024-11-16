import json
import os

import yaml


def format_time(seconds):
    """Convert seconds to HH:MM:SS format."""
    hours = int(seconds // 3600)
    minutes = int((seconds % 3600) // 60)
    seconds = int(seconds % 60)
    return f"{hours:02d}:{minutes:02d}:{seconds:02d}"


def _write_frontmatter(f, data):
    """Write YouTube metadata as Obsidian frontmatter to an open file."""
    frontmatter = {
        "youtube_url": data.get("webpage_url", f'https://www.youtube.com/watch?v={data.get("id")}'),
        "title": data.get("title"),
        "tags": [],
        "description": data.get("description", "").strip(),
        "uploader_id": data.get("uploader_id"),
        "channel": data.get("channel"),
        "upload_date": data.get("upload_date"),
        "duration": f"00:{data.get('duration', 0) // 60:02d}:{data.get('duration', 0) % 60:02d}",
        "audio_quality": data.get("audio_quality", "medium"),
    }

    f.write("---\n")
    yaml.dump(frontmatter, f, default_flow_style=False, allow_unicode=True, sort_keys=False, width=float("inf"), encoding=None)
    f.write("---\n\n")


def _write_srt_content(f, metadata, srt_content_dict):
    """Write content with chapters if available, otherwise write all text."""
    chunks_dict = srt_content_dict.get("chunks", [])
    text_segments = [{"start_time": chunk["timestamp"][0], "end_time": chunk["timestamp"][1], "text": chunk["text"].strip()} for chunk in chunks_dict]

    if metadata.get("chapters"):
        for chapter in metadata["chapters"]:
            f.write(f"## {chapter['title']}\n")
            f.write(f"{chapter['start_time']}s - {chapter['end_time']}s\n\n")

            chapter_text = []
            for segment in text_segments:
                if segment["start_time"] >= chapter["start_time"] and segment["start_time"] < chapter["end_time"]:
                    chapter_text.append(segment["text"])

            f.write(" ".join(chapter_text) + "\n\n")
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


def create_obsidian_note(output_dir, basename, obsidian_dir):
    """
    Create an Obsidian note from a YouTube video.

    Args:
        output_dir (str): Directory containing the metadata and SRT files.
        basename (str): Base filename of the metadata (.info.json) and SRT (.json) files.
        obsidian_dir (str): Directory where the Obsidian note will be created.

    Raises:
        FileNotFoundError: If metadata, SRT file or Obsidian directoryis not found.
        NotADirectoryError: If Obsidian directory path exists but is not a directory.

    """
    print("\nDEBUG VALUES:")
    print(f"output_dir: {output_dir}")
    print(f"basename: {basename}")
    print(f"obsidian_dir: {obsidian_dir}")
    metadata_file = os.path.join(output_dir, f"{basename}.info.json")
    srt_file = os.path.join(output_dir, f"{basename}.json")
    obsidian_note = os.path.join(obsidian_dir, f"{basename}.md")

    # Now check if files exist
    if not os.path.exists(metadata_file):
        raise FileNotFoundError(f"Metadata file not found : {metadata_file}")
    if not os.path.exists(srt_file):
        raise FileNotFoundError(f"SRT file not found : {srt_file}")

    print("\nDEBUG VALUES:")
    print(f"metadata_file: {metadata_file}")
    print(f"srt_file: {srt_file}")
    print(f"obsidian_dir: {obsidian_dir}")
    print("-------------------")
    # Verify obsidian directory exists
    if not os.path.exists(obsidian_dir):
        raise FileNotFoundError(f"Obsidian directory {obsidian_dir} does not exist")
    if not os.path.isdir(obsidian_dir):
        raise NotADirectoryError(f"'{obsidian_dir}' exists but is not a directory")
    # Read metadata
    print(f"Reading metadata from {metadata_file}")
    print(f"Reading SRT from {srt_file}")
    print(f"Writing to {obsidian_dir}")
    with open(metadata_file, encoding="utf-8") as f:
        metadata = json.load(f)

    # Read SRT
    with open(srt_file, encoding="utf-8") as f:
        srt_content = json.load(f)
    # Create Obsidian note

    # Create the full filepath using os.path.join to handle path separators correctly
    print(f"Writing Obsidian note to {obsidian_note}")
    with open(obsidian_note, "w", encoding="utf-8") as f:
        _write_frontmatter(f, metadata)
        _write_srt_content(f, metadata, srt_content)