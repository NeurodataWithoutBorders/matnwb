## Live Script M-Code Folder

This folder contains exported copies of all live scripts in `.m` file format. 
These scripts are **read-only** and are not intended for direct editing or 
interaction. They serve solely to enable tracking of live script changes 
through diffs in source control.

### For Developers

To update the exports after modifying a live script, run the 
`matnwb_exportModifiedTutorials` function located in 
`<matnwb_root>/tools/documentation/`. 
This function will re-export the live script as both HTML and `.m` files.
