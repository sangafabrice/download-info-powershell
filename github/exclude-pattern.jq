map(select(.tag_name |
test($ExcludeTag) | 
not)) |
.[0]