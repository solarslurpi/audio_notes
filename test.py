import os
from pathlib import Path

def read_audio_knowledge_dir():
    # Define the directory path
    dir_path = "/mnt/g/My Drive/Audios_To_Knowledge/knowledge/AskGrowBuddy/AskGrowBuddy/new_notes"

    try:
        # Convert to Path object for better cross-platform compatibility
        path = Path(dir_path)

        # Check if directory exists
        if not path.exists():
            print(f"Directory not found: {dir_path}")
            return

        # List all files and directories
        print(f"\nContents of {dir_path}:\n")
        for item in path.iterdir():
            # Get item type and size
            item_type = "Directory" if item.is_dir() else "File"
            size = os.path.getsize(item) if item.is_file() else "-"

            print(f"{item_type}: {item.name}")
            if item_type == "File":
                print(f"Size: {size} bytes")
            print("-" * 50)
    except Exception as e:
        print(f"An error occurred in read_audio_knowledge_dir: {str(e)}")

if __name__ == "__main__":
    read_audio_knowledge_dir()