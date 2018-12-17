for i = 1:length(dat)
    char = dat(i);
    if strcmp(char, '{')
        fprintf('\n');
    else
        fprintf(char)
    end
end