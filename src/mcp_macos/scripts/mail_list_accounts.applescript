on run argv
    set AppleScript's text item delimiters to linefeed
    set outLines to {}
    tell application "Mail"
        try
            repeat with acc in accounts
                set accName to (name of acc as text)
                set end of outLines to accName
            end repeat
        on error errMsg
            -- Return empty if something goes wrong (e.g., no permission)
        end try
    end tell
    return outLines as text
end run

