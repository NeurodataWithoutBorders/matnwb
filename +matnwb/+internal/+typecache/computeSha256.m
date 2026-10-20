function hash = computeSha256(text)
% computeSha256 - Compute the SHA-256 hash of a text as a hex string.
%
%   hash = matnwb.internal.typecache.computeSha256(text) returns the hash of
%   the UTF-8 encoding of text as a 64-character lowercase hex string.

    arguments
        text (1,1) string
    end

    messageDigest = java.security.MessageDigest.getInstance("SHA-256");
    digestBytes = messageDigest.digest(unicode2native(char(text), "UTF-8"));

    % Java returns signed bytes; reinterpret them as unsigned before formatting.
    unsignedBytes = typecast(int8(digestBytes), "uint8");
    hash = string(lower(reshape(dec2hex(unsignedBytes, 2)', 1, [])));
end
