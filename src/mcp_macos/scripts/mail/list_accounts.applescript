on run argv
    tell application "Mail"
        set accountNames to {}
        repeat with acc in accounts
            set end of accountNames to (name of acc as text)
        end repeat
    end tell

    if (count of accountNames) is 0 then
        return ""
    end if

    set AppleScript's text item delimiters to linefeed
    set outputText to accountNames as text
    set AppleScript's text item delimiters to ""

    return outputText
end run
