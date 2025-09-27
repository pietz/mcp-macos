on run argv
    if (count of argv) < 3 then return "ERROR: need subject, body, visible, recipients..."
    set subj to item 1 of argv
    set bdy to item 2 of argv
    set visArg to item 3 of argv
    set visBool to false
    if visArg is "true" or visArg is "TRUE" then set visBool to true
    set recips to {}
    if (count of argv) > 3 then set recips to items 4 thru -1 of argv
    tell application "Mail"
        set msg to make new outgoing message with properties {subject:subj, content:bdy, visible:visBool}
        repeat with r in recips
            tell msg to make new to recipient with properties {address:(r as text)}
        end repeat
        send msg
    end tell
    return "OK"
end run
