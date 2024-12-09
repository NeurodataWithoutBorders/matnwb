import sys
from pynwb import NWBHDF5IO

def pynwbread():
    if len(sys.argv) > 1:
        # Take the first input argument
        nwb_file_path = sys.argv[1]
        print(f"Reading file '{nwb_file_path}' with pynwb.")

        with NWBHDF5IO(nwb_file_path, "r") as io:
            read_nwbfile = io.read()

    else:
        raise Exception("No filepath was provided")

if __name__ == "__main__":
    pynwbread()