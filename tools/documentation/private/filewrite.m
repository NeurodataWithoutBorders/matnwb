function filewrite(filePath, text)
    fid = fopen(filePath, 'wt');
    fwrite(fid, text);
    fclose(fid);
end