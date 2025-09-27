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

    set mailboxName to ""
    if (count of argv) ≥ 3 then set mailboxName to item 3 of argv

    set queryText to ""
    if (count of argv) ≥ 4 then set queryText to item 4 of argv

    set previewLen to 500
    if (count of argv) ≥ 5 then
        try
            set previewLen to (item 5 of argv) as integer
        end try
    end if

    set AppleScript's text item delimiters to linefeed
    set outLines to {}

    tell application "Mail"
        set targetMailbox to inbox
        if mailboxName is not "" then
            set foundMailbox to my find_mailbox(mailboxName)
            if foundMailbox is not missing value then set targetMailbox to foundMailbox
        end if

        set msgList to messages of targetMailbox
        set collected to 0
        repeat with m in msgList
            set includeMsg to true
            set isRead to read status of m

            if statusFilter is "unread" then
                if isRead is true then set includeMsg to false
            else if statusFilter is "read" then
                if isRead is false then set includeMsg to false
            end if

            set subjectText to subject of m as text
            set senderText to sender of m as text
            set contentText to content of m as text

            if includeMsg and queryText is not "" then
                set includeMsg to my message_matches(subjectText, senderText, contentText, queryText)
            end if

            if includeMsg then
                set mailId to id of m as text
                set receivedText to date received of m as text
                set mailboxText to name of mailbox of m as text
                if isRead then
                    set readText to "true"
                else
                    set readText to "false"
                end if
                set previewText to my make_preview(contentText, previewLen)
                set lineText to my sanitize(subjectText) & tab & my sanitize(senderText) & tab & mailId & tab & my sanitize(receivedText) & tab & my sanitize(mailboxText) & tab & readText & tab & previewText
                set end of outLines to lineText
                set collected to collected + 1
                if collected ≥ limitVal then exit repeat
            end if
        end repeat
    end tell

    set AppleScript's text item delimiters to "\n"
    set resultText to outLines as text
    set AppleScript's text item delimiters to ""
    return resultText
end run

on find_mailbox(mailboxName)
    tell application "Mail"
        repeat with acc in accounts
            try
                set mb to mailbox mailboxName of acc
                if mb is not missing value then return mb
            end try
        end repeat
        try
            return mailbox mailboxName
        end try
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
