import os
import re
from _util import list_neurodata_types


def process_matlab_docstring(app, what, name, obj, options, lines):
    _format_matlab_type_as_code_literal(lines)
    _format_nwbtype_shortnames(lines)
    _make_syntax_examples_code_literals(lines)
    _format_input_arguments(lines)
    _split_and_format_example_lines(lines)


def _format_matlab_type_as_code_literal(lines):
     # Full list of MATLAB base types
    matlab_types = {
        "double", "single", "int8", "uint8", "int16", "uint16", 
        "int32", "uint32", "int64", "uint64", "logical", "char", 
        "cell", "struct", "table", "categorical", "datetime", 
        "duration", "calendarDuration", "function_handle", 
        "string", "complex"
    }

    type_pattern = re.compile(
        rf"(?P<before>\()"
        rf"(?P<type>{'|'.join(re.escape(t) for t in matlab_types)})"
        rf"(?P<after>\))"
    )
    
    for i, line in enumerate(lines):
        # Replace matches with inline code formatting, preserving parentheses
        # lines[i] = type_pattern.sub(
        #     lambda match: (
        #         f"{match.group('before') or ''}"
        #         f"``{match.group('type')}``"
        #         f"{match.group('after') or ''}"
        #     ),
        #     line
        # )
        lines[i] = type_pattern.sub(
            lambda match: (
                f"{match.group('before') or ''}"
                f":matclass:`{match.group('type')}`"
                f"{match.group('after') or ''}"
            ),
            line
        )


def _make_syntax_examples_code_literals(lines):
    """
    Process a MATLAB docstring to wrap expressions in the Syntax section with double backticks.

    Args:
        lines (str): The original MATLAB docstring lines.
    """

    in_syntax_section = False

    # Regex to match MATLAB expressions
    matlab_expr_pattern = re.compile(
        r"^\s*((?:\[[\w,\s]*\]\s*=\s*|[\w]+\s*=\s*)?[A-Za-z]\w*\([^)]*\))"
    )
    
    for i, line in enumerate(lines):
        # Check if the current line starts the Syntax section
        if line.strip().lower().startswith("syntax:"):
            in_syntax_section = True
            continue

        # Check if the current line is another section header
        if in_syntax_section and _is_section_header(line) and not line.strip().lower().startswith("syntax:"):
            in_syntax_section = False

        if in_syntax_section:
            # Wrap MATLAB expressions in double backticks
            match = matlab_expr_pattern.search(line)
            if match:
                # Need group 1 as group 0 contains the leading whitespace...?
                line = matlab_expr_pattern.sub(lambda m: f"``{m.group(1)}``", line)
                # Need to prepend a leading space, no idea why.
                lines[i] = " " + line


def _format_input_arguments(lines):
    """
    Format the 'Input Arguments' section to add double ** around item names
    and `` around types in parentheses.

    Args:
        lines (list of str): List of lines in the Input Arguments section.

    Returns:
        list of str: Formatted lines.
    """
    # Regex pattern for list item names with optional types in parentheses
    input_arg_pattern = re.compile(
        r"(?P<indent>^\s*)-\s*(?P<name>\w+)"  # Match the name of the argument
        r"(?:\s*\((?P<type>.*?)\))?"  # Optionally match the type in parentheses
    )

    for i, line in enumerate(lines):
        # Apply formatting to each matching line
        lines[i] = input_arg_pattern.sub(
            lambda match: (
                f"{match.group('indent')}- **{match.group('name').strip()}**" +  # Name
                ( # Optional type
                    f" ({match.group('type').strip()})"  # Preserve existing formatting
                    if match.group('type') and (
                        match.group('type').strip().startswith("``") or  # Already backtick-formatted
                        match.group('type').strip().startswith(":")      # Sphinx directive
                    )
                    else f" (``{match.group('type').strip()}``)"  # Add backticks if unformatted
                ) if match.group('type') else ""  # No type provided  
            ),
            line
        )

    return lines


def _split_and_format_example_lines(lines):
    """
    Split and format example lines like:
    'Example 1 - Export an NWB file:'
    into two lines:
    '**Example 1.**'
    '**Export an NWB file**::'

    Modifies the `lines` list in place.

    Args:
        lines (list of str): List of lines in the Usage section.
    """

    # Regex pattern to match example lines with descriptions
    example_pattern = re.compile(
        r"^\s*(Example\s+\d+)\s*-\s*(.*)::\s*$"  # Matches 'Example X - Description:'
    )

    i = 0
    while i < len(lines):
        # Check if the current line matches the "Example X - Description:" format
        match = example_pattern.match(lines[i])
        if match:
            example, description = match.groups()
            # Replace the original line with two formatted lines
            lines[i] = f" **{example} -**" # Important: add one space at beginning of line for proper rst indent
            lines.insert(i + 1, f" **{description}**::") # Important: add one space at beginning of line for proper rst indent
            i += 2  # Skip over the newly added line
        else:
            i += 1  # Move to the next line if no match


def _format_nwbtype_shortnames(lines):
    """
    Preprocesses a list of docstring lines to replace occurrences of patterns
    with their respective :class:`pattern` references.
    
    Modifies the list of lines in place.
    
    Parameters:
        lines (list of str): The docstring lines to preprocess.
        patterns (list of str): A list of patterns (e.g., ["TimeSeries", "DataArray"]).
    """

    patterns = list_neurodata_types('core') + list_neurodata_types('hdmf_common') 
    # Create a dictionary for replacements
    replacements = {pattern: f"(:class:`{pattern}`)" for pattern in patterns}
    
    # Compile a regex that matches any of the patterns
    regex = re.compile(r'\((' + '|'.join(map(re.escape, patterns)) + r')\)')

    # Iterate over the lines and replace matches in place
    for i in range(len(lines)):
        lines[i] = regex.sub(lambda match: replacements[match.group(1)], lines[i])


def _is_section_header(line):
    # Regex to identify section headers
    section_header_pattern = re.compile(r"^\s*%?\s*[A-Za-z ]+:")

    return section_header_pattern.match(line)
