# Outlook Parser

    $ foreman run -e Procfile.dev.env ruby mail.rb

    [1] pry(main)> token = get_access_token
    [1] pry(main)> mails = get_mails(token)
    [1] pry(main)> mail = get_mail(token, <id>)

Environment Variables

    CLIENT_ID
    CLIENT_SECRET
    TENANT
    INBOX
