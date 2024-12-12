import os

def list_neurodata_types(namespace_name):
    # Get the absolute path of the script's directory
    script_dir = os.path.dirname(os.path.abspath(__file__))

    # Compute the absolute path two levels up from the script's directory
    matnwb_src_dir = os.path.abspath(os.path.join(script_dir, '..', '..', '..'))

    # Construct the path to the namespace's types directory
    types_dir = os.path.join(matnwb_src_dir, '+types', f"+{namespace_name}")

    # List to store the file names without extension
    neurodata_types = []

    # Check if the directory exists
    if os.path.isdir(types_dir):
        # Iterate through all .m files in the directory
        for file_name in os.listdir(types_dir):
            if file_name.endswith('.m'):
                # Remove the file extension and add to the list
                neurodata_types.append(os.path.splitext(file_name)[0])

    return neurodata_types
