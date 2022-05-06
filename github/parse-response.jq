"version=\(.tag_name)",
(
    [
        (.assets |
        map(select(.name |
        (match($AssetPattern)))))|
        .[].browser_download_url
    ] |
    (
        (
            range(0,length) as $i |
            (.[$i] as $value |
            if $i == 0 then "link=\($value)"
            else "link\($i)=\($value)" end)
        ),
        "count=\(length)"
    )
)