on run argv
    set filterAccount to ""
    if (count of argv) ≥ 1 then set filterAccount to item 1 of argv
    set AppleScript's text item delimiters to linefeed
    set outLines to {}
    tell application "Mail"
        try
            repeat with acc in accounts
                set accName to (name of acc as text)
                if filterAccount is "" or accName is filterAccount then
                    repeat with mb in mailboxes of acc
                        try
                            set mbName to (name of mb as text)
                            set u to (unread count of mb)
                            set end of outLines to mbName & tab & accName & tab & (u as text)
                        end try
                    end repeat
                end if
            end repeat
        on error errMsg
            -- Return empty on error
        end try
    end tell
    return outLines as text
end run

