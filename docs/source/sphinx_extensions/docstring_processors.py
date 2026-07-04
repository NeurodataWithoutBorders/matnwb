# Patches generated MATLAB docstrings so they parse as valid reST. Fixes
# rendering only — never change what fillConstructor.m embeds in the
# generated .m source, since that text also serves plain `help` output.
#
# Root cause of the multiline cases: schema `doc:` fields are valid reST as
# written (nwb-schema's own docs render them fine, unmodified). matnwb's
# schema parsing drops the blank lines before fillConstructor.m embeds the
# text, which is what breaks it here. The proper fix is upstream (preserve
# blank lines/indentation through codegen); this module is a downstream
# workaround until that happens.
import os
import re
from _util import list_neurodata_types


def process_matlab_docstring(app, what, name, obj, options, lines):
    _format_matlab_type_as_code_literal(lines)
    _format_nwbtype_shortnames(lines)
    _format_required_properties(lines)
    _replace_class_contructor_method_role_with_class_role(lines)
    _make_syntax_examples_code_literals(lines)
    _format_input_arguments(lines)
    _split_and_format_example_lines(lines)
    _escape_role_end_before_invalid_char(lines)
    _wrap_multiline_argument_descriptions(lines)


# Characters allowed to directly follow an inline markup end-string in reST.
# See: https://docutils.sourceforge.io/docs/ref/rst/restructuredtext.html#inline-markup-recognition-rules
_ALLOWED_CHARS_AFTER_ROLE = re.compile(r"[\s'\")\]}>\-.,:;!?/\\]")

# Matches the closing backtick of an explicit-title role reference, e.g.
# ":attr:`format <types.core.ImageSeries.format>`", so a "\ " escape can be
# inserted when matlab_auto_link places such a reference directly before
# punctuation from the original schema text (e.g. "format='raw'" or
# "control_description[0]"), which would otherwise break reST parsing.
_ROLE_END_PATTERN = re.compile(r"(<[^<>`]+>)`")


def _escape_role_end_before_invalid_char(lines):
    def _insert_escape(match):
        end = match.end()
        next_char = match.string[end:end + 1]
        if next_char and not _ALLOWED_CHARS_AFTER_ROLE.match(next_char):
            return match.group(0) + "\\ "
        return match.group(0)

    for i, line in enumerate(lines):
        lines[i] = _ROLE_END_PATTERN.sub(_insert_escape, line)


# Matches the first line of a "- name (type) - description" Name-Value
# Arguments list item (as produced by file.internal.processDocstring /
# fillConstructor.m), capturing its leading indentation. Runs after
# _format_input_arguments, so the name/type may already be wrapped in
# "**...**" / "``...``" markup.
_ARG_ITEM_START_PATTERN = re.compile(r"^(?P<indent>\s*)-\s+\*{0,2}\w+\*{0,2}\s*(?:\(.*?\))?\s*-\s*\S")

# Inline markup that earlier formatting passes may have applied to a line;
# stripped from literal-block content below so diagrams/nested lists are
# shown as their original plain text rather than with stray markup chars.
_INLINE_MARKUP_PATTERNS = (
    re.compile(r":[\w:]+:`([^`<]+?)\s*<[^>]+>`\\?\s*"),
    re.compile(r":[\w:]+:`([^`]+?)`"),
    re.compile(r"\*\*(.+?)\*\*"),
    re.compile(r"``(.+?)``"),
)


def _strip_inline_markup(line):
    for pattern in _INLINE_MARKUP_PATTERNS:
        line = pattern.sub(r"\1", line)
    return line


def _wrap_multiline_argument_descriptions(lines):
    """
    Some schema descriptions (YAML literal block scalars) span multiple
    lines and may contain nested bullet lists, ASCII diagrams, or other
    structured text. By the time it reaches this docstring, that content
    has already lost the blank lines and relative indentation that made it
    valid reST in the schema source (see module note above), so it fails
    to parse here (e.g. a nested list immediately following a paragraph
    with no blank line). Render the continuation as a reST literal block
    instead, so it is always displayed verbatim rather than being
    (mis-)parsed as reST.

    Modifies the `lines` list in place.
    """

    i = 0
    while i < len(lines):
        match = _ARG_ITEM_START_PATTERN.match(lines[i])
        if not match:
            i += 1
            continue

        item_index = i
        i += 1
        continuation_start = i
        while i < len(lines) and lines[i].strip() != "":
            i += 1
        continuation = lines[continuation_start:i]

        if not continuation:
            continue

        literal_indent = match.group("indent") + "    "
        literal_lines = [literal_indent + _strip_inline_markup(cline) for cline in continuation]

        lines[item_index] += "::"
        lines[continuation_start:i] = [""] + literal_lines
        i = continuation_start + len(literal_lines) + 1

    return lines


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


def _format_required_properties(lines):
    """
    Process lines to find the 'Required Properties' section and format its values.

    Args:
        lines (list of str): Lines from a docstring to process.
    """
    
    try:
        # Find the index of the "Required Properties:" line
        required_idx = next(i for i, line in enumerate(lines) if "Required Properties:" in line)
        
        if not required_idx: 
            return

        lines[required_idx] = lines[required_idx].replace("Required Properties:", "Required Properties\ `*`__:")

        # Process the line following "Required Properties:"
        required_line = lines[required_idx + 1]

        values = required_line.strip().split(", ")

        # Format the values
        formatted_values = [
            f":attr:`{value.strip()}`" if value.lower() != "none" else f"``{value.strip()}``"
            for value in values
        ]
        # Update the line with required properties. Add single preceding space
        # for proper indentation
        lines[required_idx + 1] = " " + ", ".join(formatted_values)
    
    except (StopIteration, IndexError):
        # If "Required Properties:" or the following line is not found, return the original lines
        pass


def _replace_class_contructor_method_role_with_class_role(lines):
    """
    Process docstrings to replace `:meth:` expressions with `:class:`.

    Args:
        lines: List of lines in the docstring.
    """
    
    # Regular expression to match the `:meth:` pattern
    pattern = re.compile(
        r":meth:`([^`]+)\s*<([a-zA-Z0-9_.]+)\.([a-zA-Z0-9_]+)\.([a-zA-Z0-9_]+)>`"
    )

    # Replacement function for re.sub
    def replace_meth_with_class(match):
        display_name = match.group(1).replace("()", "").strip()  # The displayed name, e.g., "AbstractFeatureSeries"
        namespace_prefix = match.group(2)  # The module path, e.g., "types.core"
        class_name = match.group(3)  # The class name, e.g., "AbstractFeatureSeries"
        # Construct the new :class: pattern
        return f":class:`{display_name} <{namespace_prefix}.{class_name}>`"

    # Update lines in place
    for i, line in enumerate(lines):
        lines[i] = pattern.sub(replace_meth_with_class, line)


def _make_syntax_examples_code_literals(lines):
    """
    Process a MATLAB docstring to wrap expressions in the Syntax section with double backticks.

    Args:
        lines (str): The original MATLAB docstring lines.
    """

    in_syntax_section = False

    # Regex to match MATLAB expressions
    matlab_expr_pattern = re.compile(
        r"^\s*((?:\[[\w,\s]*\]\s*=\s*|[\w]+\s*=\s*)?[A-Za-z][\w\.]*\([^)]*\))"
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
            # Strip RST role markup before matching: auto_link may have already
            # converted identifiers to :class:`X <Y>` or :meth:`X() <Y>` roles.
            # Syntax examples are code — links inside them are unwanted and also
            # break the MATLAB expression pattern (line starts with ':' not a word).
            clean = re.sub(r':[\w:]+:`([^`<]+?)\s*<[^>]+>`', r'\1', line)
            clean = re.sub(r':[\w:]+:`([^`]+?)`', r'\1', clean)
            match = matlab_expr_pattern.search(clean)
            if match:
                clean = matlab_expr_pattern.sub(lambda m: f"``{m.group(1)}``", clean)
                lines[i] = " " + clean


def _format_input_arguments(lines):
    """
    Format the 'Input Arguments' section to add double ** around item names
    and `` around types in parentheses.

    Args:
        lines (list of str): List of lines in the Input Arguments section.
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
                if match.group('type') else "" )  # No type provided  
            ),
            line
        )
        

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
    # Regex to identify section headers.
    # Must start with a letter (not space) to avoid matching RST roles like
    # :class:`X` where backtracking would let [A-Za-z ] match a leading space.
    section_header_pattern = re.compile(r"^\s*%?\s*[A-Za-z][A-Za-z ]*:")

    return section_header_pattern.match(line)
