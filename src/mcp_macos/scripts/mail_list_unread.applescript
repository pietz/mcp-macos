on run argv
    set limitVal to 10
    if (count of argv) >= 1 then
        try
            set limitVal to (item 1 of argv) as integer
        end try
    end if
    set AppleScript's text item delimiters to linefeed
    set outLines to {}
    set i to 0
    tell application "Mail"
        set msgList to (messages of inbox whose read status is false)
        repeat with m in msgList
            set i to i + 1
            set s to (subject of m as text)
            set snd to (sender of m as text)
            set mid to (id of m as text)
            set dr to (date received of m as text)
            set end of outLines to s & tab & snd & tab & mid & tab & dr
            if i >= limitVal then exit repeat
        end repeat
    end tell
    return outLines as text
end run
