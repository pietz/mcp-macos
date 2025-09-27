on run argv
    set limitVal to 10
    if (count of argv) ≥ 1 then
        try
            set limitVal to (item 1 of argv) as integer
        end try
    end if
    if limitVal < 1 then set limitVal to 1
    if limitVal > 30 then set limitVal to 30

    set statusFilter to "any"
    if (count of argv) ≥ 2 then set statusFilter to item 2 of argv
    if statusFilter is "all" then set statusFilter to "any"

    set accountName to ""
    if (count of argv) ≥ 3 then set accountName to item 3 of argv

    set mailboxName to ""
    if (count of argv) ≥ 4 then set mailboxName to item 4 of argv

    set queryText to ""
    if (count of argv) ≥ 5 then set queryText to item 5 of argv

    set previewLen to 500
    if (count of argv) ≥ 6 then
        try
            set previewLen to (item 6 of argv) as integer
        end try
    end if

    set AppleScript's text item delimiters to linefeed
    set outLines to {}

    tell application "Mail"
        set collected to 0
        if mailboxName is "" or mailboxName is "Inbox" then
            -- First try the unified global Inbox (some setups populate this)
            try
                set globalMsgs to messages of inbox
                repeat with m in globalMsgs
                    set includeMsg to true
                    set isRead to read status of m
                    if statusFilter is "unread" then
                        if isRead is true then set includeMsg to false
                    else if statusFilter is "read" then
                        if isRead is false then set includeMsg to false
                    end if
                    set subjectText to subject of m as text
                    set senderText to sender of m as text
                    set contentText to ""
                    if includeMsg and queryText is not "" then
                        set contentText to content of m as text
                        set includeMsg to my message_matches(subjectText, senderText, contentText, queryText)
                    end if
                    if includeMsg then
                        if contentText is "" then set contentText to content of m as text
                        set mailId to id of m as text
                        set receivedText to date received of m as text
                        set accName to ""
                        try
                            set accName to (name of account of mailbox of m as text)
                        end try
                        if accountName is not "" and accName is not accountName then
                            set includeMsg to false
                        end if
                        if isRead then
                            set readText to "true"
                        else
                            set readText to "false"
                        end if
                        if includeMsg then
                            set previewText to my make_preview(contentText, previewLen)
                            set statusText to ("Read")
                            if readText is "false" then set statusText to "Unread"
                            set lineText to mailId & tab & my sanitize(receivedText) & tab & my sanitize(senderText) & tab & my sanitize(accName) & tab & statusText & tab & my sanitize(subjectText) & tab & previewText
                            set end of outLines to lineText
                            set collected to collected + 1
                            if collected ≥ limitVal then exit repeat
                        end if
                    end if
                end repeat
            end try
            -- If not enough collected, also iterate each account's Inbox
            if collected < limitVal then
                repeat with acc in accounts
                    try
                        set accInbox to mailbox "Inbox" of acc
                        set accName to (name of acc as text)
                        if accountName is "" or accName is accountName then
                            set accMsgs to messages of accInbox
                            repeat with m in accMsgs
                                set includeMsg to true
                                set isRead to read status of m
                                if statusFilter is "unread" then
                                    if isRead is true then set includeMsg to false
                                else if statusFilter is "read" then
                                    if isRead is false then set includeMsg to false
                                end if
                                set subjectText to subject of m as text
                                set senderText to sender of m as text
                                set contentText to ""
                                if includeMsg and queryText is not "" then
                                    set contentText to content of m as text
                                    set includeMsg to my message_matches(subjectText, senderText, contentText, queryText)
                                end if
                                if includeMsg then
                                    if contentText is "" then set contentText to content of m as text
                                    set mailId to id of m as text
                                    set receivedText to date received of m as text
                                    if isRead then
                                        set readText to "true"
                                    else
                                        set readText to "false"
                                    end if
                                    set previewText to my make_preview(contentText, previewLen)
                                    set statusText to ("Read")
                                    if readText is "false" then set statusText to "Unread"
                                    set lineText to mailId & tab & my sanitize(receivedText) & tab & my sanitize(senderText) & tab & my sanitize(accName) & tab & statusText & tab & my sanitize(subjectText) & tab & previewText
                                    set end of outLines to lineText
                                    set collected to collected + 1
                                    if collected ≥ limitVal then exit repeat
                                end if
                            end repeat
                        end if
                    end try
                    if collected ≥ limitVal then exit repeat
                end repeat
            end if
        else
            set foundMailbox to my find_mailbox(mailboxName, accountName)
            if foundMailbox is not missing value then
                set accMsgs to messages of foundMailbox
                -- Try to resolve account name for this mailbox
                set accName to ""
                try
                    tell application "Mail"
                        repeat with a in accounts
                            try
                                set accountLabel to (name of a as text)
                                if accountName is not "" and accountLabel is not accountName then
                                    -- skip non-matching accounts when filtering
                                else
                                    set mbs to mailboxes of a
                                    if mbs contains foundMailbox then
                                        set accName to accountLabel
                                        exit repeat
                                    end if
                                end if
                            end try
                        end repeat
                    end tell
                end try
                repeat with m in accMsgs
                    set includeMsg to true
                    set isRead to read status of m
                    if statusFilter is "unread" then
                        if isRead is true then set includeMsg to false
                    else if statusFilter is "read" then
                        if isRead is false then set includeMsg to false
                    end if
                    set subjectText to subject of m as text
                    set senderText to sender of m as text
                    set contentText to ""
                    if includeMsg and queryText is not "" then
                        set contentText to content of m as text
                        set includeMsg to my message_matches(subjectText, senderText, contentText, queryText)
                    end if
                    if includeMsg then
                        if contentText is "" then set contentText to content of m as text
                        set mailId to id of m as text
                        set receivedText to date received of m as text
                        if accountName is not "" and accName is not accountName then
                            set includeMsg to false
                        end if
                        if isRead then
                            set readText to "true"
                        else
                            set readText to "false"
                        end if
                        if includeMsg then
                            set previewText to my make_preview(contentText, previewLen)
                            set statusText to ("Read")
                            if readText is "false" then set statusText to "Unread"
                            set lineText to mailId & tab & my sanitize(receivedText) & tab & my sanitize(senderText) & tab & my sanitize(accName) & tab & statusText & tab & my sanitize(subjectText) & tab & previewText
                            set end of outLines to lineText
                            set collected to collected + 1
                            if collected ≥ limitVal then exit repeat
                        end if
                    end if
                end repeat
            end if
        end if
    end tell

    set AppleScript's text item delimiters to "\n"
    set resultText to outLines as text
    set AppleScript's text item delimiters to ""
    return resultText
end run

on find_mailbox(mailboxName, accountName)
    tell application "Mail"
        if accountName is not "" then
            repeat with acc in accounts
                try
                    if (name of acc as text) is accountName then
                        try
                            return mailbox mailboxName of acc
                        end try
                    end if
                end try
            end repeat
        else
            repeat with acc in accounts
                try
                    set mb to mailbox mailboxName of acc
                    if mb is not missing value then return mb
                end try
            end repeat
            try
                return mailbox mailboxName
            end try
        end if
    end tell
    return missing value
end find_mailbox

on message_matches(subjectText, senderText, contentText, queryText)
    set includeMsg to false
    if subjectText contains queryText then set includeMsg to true
    if includeMsg is false and senderText contains queryText then set includeMsg to true
    if includeMsg is false and contentText contains queryText then set includeMsg to true
    return includeMsg
end message_matches

on sanitize(value)
    set cleaned to my replace_chars(value, tab, " ")
    set cleaned to my replace_chars(cleaned, return, " ")
    set cleaned to my replace_chars(cleaned, linefeed, " ")
    return cleaned
end sanitize

on make_preview(contentText, maxLen)
    set cleaned to my sanitize(contentText)
    if maxLen > 0 then
        try
            if (count cleaned) > maxLen then
                set cleaned to text 1 thru maxLen of cleaned
            end if
        end try
    end if
    return cleaned
end make_preview

on replace_chars(t, searchValue, replacementValue)
    if t is missing value then return ""
    set originalDelims to AppleScript's text item delimiters
    set AppleScript's text item delimiters to searchValue
    set parts to every text item of t
    set AppleScript's text item delimiters to replacementValue
    set newText to parts as text
    set AppleScript's text item delimiters to originalDelims
    return newText
end replace_chars
