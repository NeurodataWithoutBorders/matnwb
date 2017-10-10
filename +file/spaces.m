function s = spaces(num)
validateattributes(num, {'numeric'}, {'scalar', '>', 0});
s = repmat(' ', 1, num);
end