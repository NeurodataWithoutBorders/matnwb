import os
from sphinx.ext import linkcode
import inspect
import shutil

def copy_files():
    # Get the absolute path of the script's directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    
    # Replace the linkcode module with custom linkcode module
    source_module_path = os.path.join(script_dir, 'linkcode.py')
    target_module_path = inspect.getfile(linkcode)
    shutil.copy(source_module_path, target_module_path)

    print( f'Copied "{source_module_path}" to "{target_module_path}".')

if __name__ == '__main__':
    copy_files()