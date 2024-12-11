import os
from sphinx.ext import linkcode
import inspect
import shutil

def copy_files():
    # Get the absolute path of the script's directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    
    # Replace the linkcode script with custom script
    linkcode_path = inspect.getfile(linkcode)
    print( os.path.join(script_dir, 'linkcode.py') )
    shutil.copy(os.path.join(script_dir, 'linkcode.py'), linkcode_path)

