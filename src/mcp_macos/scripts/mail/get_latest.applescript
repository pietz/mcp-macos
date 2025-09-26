on run argv
    set limitValue to 10
    set accountName to ""
    set mailboxName to ""

    if (count of argv) > 0 then
        set limitArg to item 1 of argv
        if limitArg is not "" then
            try
                set limitValue to limitArg as integer
            on error
                set limitValue to 10
            end try
        end if
    end if

    if (count of argv) > 1 then
        set accountName to item 2 of argv
    end if

    if (count of argv) > 2 then
        set mailboxName to item 3 of argv
    end if

    if limitValue < 1 then set limitValue to 1
    if limitValue > 50 then set limitValue to 50

    set collected to {}

    tell application "Mail"
        set targetAccounts to {}
        if accountName is "" then
            set targetAccounts to accounts
        else
            repeat with acc in accounts
                if (name of acc as text) is accountName then
                    set end of targetAccounts to acc
                end if
            end repeat
        end if

        repeat with acc in targetAccounts
            set accountLabel to (name of acc as text)

            set targetMailboxes to {}
            if mailboxName is "" then
                try
                    set targetMailboxes to {inbox of acc}
                on error
                    set targetMailboxes to {}
                end try
            else
                try
                    set targetMailboxes to {mailbox mailboxName of acc}
                on error
                    set targetMailboxes to {}
                end try
            end if

            repeat with mbx in targetMailboxes
                set mailboxLabel to (name of mbx as text)
                set latestMessages to messages of mbx

                repeat with msg in latestMessages
                    set end of collected to my format_message(msg, accountLabel, mailboxLabel)
                    if (count of collected) ≥ limitValue then exit repeat
                end repeat

                if (count of collected) ≥ limitValue then exit repeat
            end repeat

            if (count of collected) ≥ limitValue then exit repeat
        end repeat
    end tell

    return "[" & my join_list(collected, ",") & "]"
end run

on format_message(msg, accountLabel, mailboxLabel)
    tell application "Mail"
        set subjectText to (subject of msg as text)
        set senderText to (sender of msg as text)
        set idText to ""
        try
            set idText to (message id of msg as text)
        on error
            set idText to ""
        end try
        set dateText to ((date sent of msg) as text)
        set isRead to (read status of msg)
        set previewText to ""
        try
            set rawContent to (content of msg as text)
            if (length of rawContent) > 400 then
                set previewText to (characters 1 thru 400 of rawContent) as text
                set previewText to previewText & "..."
            else
                set previewText to rawContent
            end if
        on error
            set previewText to ""
        end try
    end tell

    set jsonText to "{"
    set jsonText to jsonText & "\"subject\":\"" & my escape_text(subjectText) & "\"," 
    set jsonText to jsonText & "\"sender\":\"" & my escape_text(senderText) & "\"," 
    set jsonText to jsonText & "\"date\":\"" & my escape_text(dateText) & "\"," 
    set jsonText to jsonText & "\"account\":\"" & my escape_text(accountLabel) & "\"," 
    set jsonText to jsonText & "\"mailbox\":\"" & my escape_text(mailboxLabel) & "\"," 
    if isRead then
        set jsonText to jsonText & "\"is_read\":true,"
    else
        set jsonText to jsonText & "\"is_read\":false,"
    end if
    set jsonText to jsonText & "\"id\":\"" & my escape_text(idText) & "\"," 
    set jsonText to jsonText & "\"preview\":\"" & my escape_text(previewText) & "\""
    set jsonText to jsonText & "}"

    return jsonText
end format_message

on join_list(itemsList, separator)
    if (count of itemsList) is 0 then
        return ""
    end if

    set AppleScript's text item delimiters to separator
    set joinedText to itemsList as text
    set AppleScript's text item delimiters to ""
    return joinedText
end join_list

on escape_text(theText)
    set cleanedText to my replace_text(theText, "\\", "\\\\")
    set cleanedText to my replace_text(cleanedText, "\"", "\\\"")
    set cleanedText to my replace_text(cleanedText, return, "\\n")
    set cleanedText to my replace_text(cleanedText, linefeed, "\\n")
    set cleanedText to my replace_text(cleanedText, tab, "\\t")
    return cleanedText
end escape_text

on replace_text(theText, searchString, replacementString)
    if searchString is "" then return theText

    set prevDelims to AppleScript's text item delimiters
    set AppleScript's text item delimiters to searchString
    set theItems to every text item of theText
    set AppleScript's text item delimiters to replacementString
    set theText to theItems as text
    set AppleScript's text item delimiters to prevDelims
    return theText
end replace_text
