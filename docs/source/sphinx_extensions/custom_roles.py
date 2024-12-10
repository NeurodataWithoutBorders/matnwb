import os
from sphinx.roles import XRefRole
from docutils import nodes, utils
from pprint import pprint
from _util import list_neurodata_types


class MatClassRole(XRefRole):
    def process_link(self, env, refnode, has_explicit_title, title, target):
        """
        Process the link for fundamental matlab classes.
        """

        # External class handling
        base_url = "https://www.mathworks.com/help/matlab/ref/"
        refnode["refuri"] = f"{base_url}{target}.html"
        #refnode["mat:class"] = env.temp_data.get("mat:class")
        #refnode["reftype"] = "class"
        #print(refnode["mat:class"])
        #print(refnode["refuri"])
        if not has_explicit_title:
            title = target
        return title, target
    
    # Could this method be a way to fix the transformation to a file:// uri for the link target?
    #def result_nodes(self, document, env, node, is_ref):
    #    pprint(vars(node))
    #    return [node], []


def register_matlab_types(app, env, docname):
    """
    Register MATLAB types in the 'mat' domain with external links.
    """
    
    # MATLAB types and their corresponding external URLs
    matlab_types = {
        "double": "https://www.mathworks.com/help/matlab/ref/double.html",
        "single": "https://www.mathworks.com/help/matlab/ref/single.html",
        "int8": "https://www.mathworks.com/help/matlab/ref/int8.html",
        "uint8": "https://www.mathworks.com/help/matlab/ref/uint8.html",
        "int16": "https://www.mathworks.com/help/matlab/ref/int16.html",
        "uint16": "https://www.mathworks.com/help/matlab/ref/uint16.html",
        "int32": "https://www.mathworks.com/help/matlab/ref/int32.html",
        "uint32": "https://www.mathworks.com/help/matlab/ref/uint32.html",
        "int64": "https://www.mathworks.com/help/matlab/ref/int64.html",
        "uint64": "https://www.mathworks.com/help/matlab/ref/uint64.html",
        "logical": "https://www.mathworks.com/help/matlab/ref/logical.html",
        "char": "https://www.mathworks.com/help/matlab/ref/char.html",
        "cell": "https://www.mathworks.com/help/matlab/ref/cell.html",
        "struct": "https://www.mathworks.com/help/matlab/ref/struct.html",
        "table": "https://www.mathworks.com/help/matlab/ref/table.html",
        "categorical": "https://www.mathworks.com/help/matlab/ref/categorical.html",
        "datetime": "https://www.mathworks.com/help/matlab/ref/datetime.html",
        "duration": "https://www.mathworks.com/help/matlab/ref/duration.html",
        "calendarDuration": "https://www.mathworks.com/help/matlab/ref/calendarduration.html",
        "function_handle": "https://www.mathworks.com/help/matlab/ref/function_handle.html",
        "string": "https://www.mathworks.com/help/matlab/ref/string.html",
        "complex": "https://www.mathworks.com/help/matlab/ref/complex.html",
    }

    # Add MATLAB types to the mat domain
    if "objects" not in env.domaindata["mat"]:
        env.domaindata["mat"]["objects"] = {}

    for type_name, url in matlab_types.items():
        # Register the type with a special 'external' object type
        env.domaindata["mat"]["objects"][type_name] = (url, "matclass")


def register_type_short_names(app, env, docname):
# register_type_short_names - Register short names for neurodata types as classes

    if "objects" not in env.domaindata["mat"]:
        env.domaindata["mat"]["objects"] = {}

    # List of modules to process
    modules = ["core", "hdmf_common", "hdmf_experimental"]
    
    # Loop through the modules
    for module in modules:
        # List the neurodata types for the current module
        nwb_types = list_neurodata_types(module)
        for type_name in nwb_types:
            # Register the type with as a 'class' object type
            docname = f"pages/neurodata_types/{module}/{type_name}"
            env.domaindata["mat"]["objects"][type_name] = (docname, "class")

