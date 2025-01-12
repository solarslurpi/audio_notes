import click

from .note_creator import create_obsidian_note

OBSIDIAN_DIR = "/mnt/g/My Drive/Audios_To_Knowledge/knowledge/AskGrowBuddy/AskGrowBuddy/new_notes"


@click.command()
@click.argument("output_dir", type=click.Path())
@click.argument("basename")
# If optional, the default is used.
@click.argument("obsidian_dir", required=False, default=OBSIDIAN_DIR)
# Not used by yt2o.sh
@click.option("--mp3-source", help="Path to source MP3 file")
@click.option("--debug", is_flag=True, help="Print debug information")
def main(output_dir, basename, obsidian_dir, mp3_source, debug):
    """Create an Obsidian note from transcription files."""
    if debug:
        click.echo("DEBUG VALUES:")
        click.echo(f"output_dir: {output_dir}")
        click.echo(f"basename: {basename}")
        click.echo(f"obsidian_dir: {obsidian_dir}")
        click.echo(f"mp3_source: {mp3_source}")
        click.echo("-------------------")
        return  # Exit after debug output

    create_obsidian_note(output_dir, basename, obsidian_dir, mp3_source)


if __name__ == "__main__":
    main()
