function tf = isUrl(location)
% isUrl - True for an http:// or https:// location.
%
% tf = isUrl(location) reports whether location names a resource on a web
% server rather than a path on a file system.

    arguments
        location (1,1) string
    end

    tf = startsWith(location, ["http://", "https://"], "IgnoreCase", true);
end
