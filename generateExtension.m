function generateExtension(varargin)
% GENERATEEXTENSION Generate Matlab classes from NWB extension schema file
%   GENERATEEXTENSION(extension_path...)  Generate classes
%   (Matlab m-files) from one or more NWB:N schema extension namespace
%   files.  A registry of already generated core types is used to resolve
%   dependent types.
%
%   A cache of schema data is generated in the 'namespaces' subdirectory in
%   the current working directory.  This is for allowing cross-referencing
%   classes between multiple namespaces.
%
%   Output files are generated placed in a '+types' subdirectory in the
%   current working directory.
%
%   Example:
%      generateExtension('schema\myext\myextension.namespace.yaml', 'schema\myext2\myext2.namespace.yaml');
%
%   See also GENERATECORE
for i = 1:length(varargin)
    source = varargin{i};
    validateattributes(source, {'char', 'string'}, {'scalartext'});
    
    [localpath, ~, ~] = fileparts(source);
    assert(2 == exist(source, 'file'),...
        'MATNWB:FILE', 'Path to file `%s` could not be found.', source);
    fid = fopen(source);
    namespaceText = fread(fid, '*char') .';
    fclose(fid);
    
    Namespace = spec.generate(namespaceText, localpath);
    file.writeNamespace(Namespace.name);
    rehash();
end
end