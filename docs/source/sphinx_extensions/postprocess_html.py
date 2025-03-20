import os
import re
import sys

def replace_text_in_html_files(directory=None):

    if directory is None:
        # Get the absolute path of the script's directory
        script_dir = os.path.dirname(os.path.abspath(__file__))
        
        # Create the absolute path for the built html
        directory = os.path.abspath(os.path.join(script_dir, '..', '..', 'build', 'html'))

    old_text = "Edit on GitHub"
    new_text = "MatNWB on GitHub"
    main_repo_url = "https://github.com/NeurodataWithoutBorders/matnwb"

    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith(".html"):
                file_path = os.path.join(root, file)

                # Read the file content
                with open(file_path, "r", encoding="utf-8") as f:
                    content = f.read()

                # Regex to match the href inside the GitHub link
                pattern = r'(<a href=\")[^\"]*(\" class=\"fa fa-github\"> Edit on GitHub</a>)'
                replacement = r'\1' + main_repo_url + r'\2'
            
                # Replace the href url using re.sub
                updated_content = re.sub(pattern, replacement, content)

                # Replace the text for the label
                updated_content = updated_content.replace(old_text, new_text)

                # Write the updated content back to the file
                with open(file_path, "w", encoding="utf-8") as f:
                    f.write(updated_content)

if __name__ == '__main__':
    directory = sys.argv[1]
    replace_text_in_html_files(directory)
