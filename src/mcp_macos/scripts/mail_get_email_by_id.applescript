on run argv
    if (count of argv) < 1 then return ""
    set targetId to (item 1 of argv) as text
    set AppleScript's text item delimiters to linefeed

    -- Sanitizers
    script San
        on sanitize(value)
            set cleaned to my replace_chars(value, tab, " ")
            set cleaned to my replace_chars(cleaned, return, " ")
            set cleaned to my replace_chars(cleaned, linefeed, " ")
            return cleaned
        end sanitize
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
    end script

    tell application "Mail"
        try
            set targetMessage to missing value
            repeat with acc in accounts
                repeat with mb in mailboxes of acc
                    try
                        set msgs to (every message of mb whose id is (targetId as integer))
                        if (count of msgs) > 0 then
                            set targetMessage to item 1 of msgs
                            exit repeat
                        end if
                    end try
                end repeat
                if targetMessage is not missing value then exit repeat
            end repeat

            if targetMessage is missing value then return ""

            set subj to (subject of targetMessage as text)
            set sndr to (sender of targetMessage as text)
            set mid to (id of targetMessage as text)
            set dr to (date received of targetMessage as text)
            set accName to ""
            try
                set accName to (name of account of mailbox of targetMessage as text)
            end try
            set rstat to (read status of targetMessage)
            if rstat then
                set statusText to "Read"
            else
                set statusText to "Unread"
            end if
            set bodyText to (content of targetMessage as text)

            -- Order: id, datetime, from, account, status, subject, body
            set lineText to mid & tab & San's sanitize(dr) & tab & San's sanitize(sndr) & tab & San's sanitize(accName) & tab & statusText & tab & San's sanitize(subj) & tab & San's sanitize(bodyText)
            return lineText
        on error errMsg
            return ""
        end try
    end tell
end run
