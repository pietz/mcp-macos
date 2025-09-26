on run argv
    set accountName to ""
    if (count of argv) > 0 then
        set accountName to item 1 of argv
    end if

    set mailboxEntries to {}

    tell application "Mail"
        if accountName is "" then
            repeat with acc in accounts
                set mailboxEntries to mailboxEntries & my collect_mailboxes_for_account(acc)
            end repeat
        else
            repeat with acc in accounts
                if (name of acc as text) is accountName then
                    set mailboxEntries to mailboxEntries & my collect_mailboxes_for_account(acc)
                end if
            end repeat
        end if
    end tell

    if (count of mailboxEntries) is 0 then
        return ""
    end if

    set AppleScript's text item delimiters to linefeed
    set outputText to mailboxEntries as text
    set AppleScript's text item delimiters to ""

    return outputText
end run

on collect_mailboxes_for_account(acc)
    set results to {}
    set accountName to (name of acc as text)
    tell application "Mail"
        set accountMailboxes to mailboxes of acc
        repeat with mbx in accountMailboxes
            set mailboxName to (name of mbx as text)
            set end of results to accountName & tab & mailboxName
        end repeat
    end tell
    return results
end collect_mailboxes_for_account
