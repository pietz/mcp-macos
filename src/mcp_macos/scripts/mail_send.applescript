on run argv
    if (count of argv) < 5 then return "ERROR: need subject, body, message_id, to_count, cc_count"
    set subj to item 1 of argv
    set bdy to item 2 of argv
    set msgIdArg to item 3 of argv
    set toCount to my parse_integer(item 4 of argv)
    set ccCount to my parse_integer(item 5 of argv)

    set expectedArgs to 5 + toCount + ccCount
    if (count of argv) < expectedArgs then return "ERROR: insufficient recipient arguments"

    set toRecipients to {}
    set ccRecipients to {}

    if toCount > 0 then
        repeat with i from 1 to toCount
            set end of toRecipients to item (5 + i) of argv
        end repeat
    end if

    if ccCount > 0 then
        repeat with i from 1 to ccCount
            set end of ccRecipients to item (5 + toCount + i) of argv
        end repeat
    end if

    tell application "Mail"
        if msgIdArg is "" then
            set msg to make new outgoing message with properties {subject:subj, content:bdy, visible:false}
            repeat with r in toRecipients
                tell msg to make new to recipient with properties {address:(r as text)}
            end repeat
            repeat with r in ccRecipients
                tell msg to make new cc recipient with properties {address:(r as text)}
            end repeat
        else
            set msg to my build_response_message(msgIdArg, toRecipients, ccRecipients, subj, bdy)
        end if
        if msg is missing value then return "ERROR: unable to prepare message"
        send msg
    end tell
    return "OK"
end run

on build_response_message(msgIdArg, toRecipients, ccRecipients, subj, bdy)
    set targetMessage to my find_message_by_id(msgIdArg)
    if targetMessage is missing value then return missing value

    set senderAddress to sender of targetMessage as text
    set isReply to false
    if (count of toRecipients) = 1 then
        if my addresses_match(senderAddress, item 1 of toRecipients) then set isReply to true
    end if

    tell application "Mail"
        if isReply then
            set msg to reply targetMessage opening window false
        else
            set msg to forward targetMessage opening window false
        end if

        -- clear default recipients
        try
            tell msg to delete every to recipient
        end try
        try
            tell msg to delete every cc recipient
        end try

        repeat with r in toRecipients
            set addressText to (r as text)
            if addressText is not "" then
                tell msg to make new to recipient with properties {address:addressText}
            end if
        end repeat

        repeat with r in ccRecipients
            set addressText to (r as text)
            if addressText is not "" then
                tell msg to make new cc recipient with properties {address:addressText}
            end if
        end repeat

        set subject of msg to subj
        set content of msg to bdy
        set visible of msg to false
        return msg
    end tell
end build_response_message

on find_message_by_id(targetId)
    if targetId is "" then return missing value
    set targetText to targetId as text
    tell application "Mail"
        try
            repeat with acc in accounts
                repeat with mb in mailboxes of acc
                    try
                        set msgs to (every message of mb whose id is (targetText as integer))
                        if (count of msgs) > 0 then return item 1 of msgs
                    end try
                end repeat
            end repeat
        end try
    end tell
    return missing value
end find_message_by_id

on addresses_match(a, b)
    set addrA to my extract_address(a)
    set addrB to my extract_address(b)
    if addrA is "" or addrB is "" then return false
    considering case is false
        if addrA = addrB then return true
    end considering
    return false
end addresses_match

on extract_address(rawValue)
    if rawValue is missing value then return ""
    set txt to rawValue as text
    set txt to my trim_text(txt)
    if txt contains "<" and txt contains ">" then
        set AppleScript's text item delimiters to "<"
        set parts to text items of txt
        if (count of parts) ≥ 2 then set txt to item 2 of parts
        set AppleScript's text item delimiters to ">"
        set parts to text items of txt
        if (count of parts) ≥ 1 then set txt to item 1 of parts
    end if
    set AppleScript's text item delimiters to ""
    return my trim_text(txt)
end extract_address

on trim_text(rawValue)
    if rawValue is missing value then return ""
    set txt to rawValue as text
    set cont to true
    repeat while cont is true and (count txt) > 0
        set firstChar to character 1 of txt
        if firstChar is space or firstChar is tab or firstChar is return or firstChar is linefeed then
            if (count txt) > 1 then
                set txt to text 2 thru -1 of txt
            else
                set txt to ""
            end if
        else
            set cont to false
        end if
    end repeat
    set cont to true
    repeat while cont is true and (count txt) > 0
        set lastChar to character -1 of txt
        if lastChar is space or lastChar is tab or lastChar is return or lastChar is linefeed then
            if (count txt) > 1 then
                set txt to text 1 thru -2 of txt
            else
                set txt to ""
            end if
        else
            set cont to false
        end if
    end repeat
    return txt
end trim_text

on parse_integer(rawValue)
    try
        return rawValue as integer
    on error
        return 0
    end try
end parse_integer
