Logmaster
=========

An enhanced logger library that handles different types of loggers
(at the moment STDOUT and FILE) and sends emails if email config is provided.

It can also watch and rescue exceptions logging them as FATAL.

Here's a usage example listing all of the possible options:


    logmaster = Logmaster.new(
      log_level:       Logger::WARN,         # Default is Logger::INFO
      file:            '/var/log/myapp.log', # if nil, will not log into any file
      stdout:          true,       # if false, will not log into STDOUR
      raise_exception: false,      # if true, will a raise an Exception after logging it
      email_config:    nil,        # see email config options below
      name:            "Logmaster" # currently useful for the email subjects,
                                   # so you can see who's emailing you
    )

    logmaster.warn("This is a warning message") # logs into file and into the STDOUT
    logmaster.info("This is an info message")   # doesn't log anything, log level isn't sufficient


Sending email notifications
---------------------------
Logmaster can also send emails. It uses Pony (https://github.com/benprew/pony) to do that. Pony usually
makes use of sendmail, but you can also specify SMTP options. See Pony docs to learn more. In our
example I will use the sendmail (which is default):

    logmaster = Logmaster.new( email_config: { to: 'me@email.foo', from: "logmaster@yourapp.com", log_level: :warn })
    logmaster.warn("Wow, this is another warning!")

The second line will trigger sending an email to your address. `:log_level` option allows to set which types of
log entries are sent in an email. For example, you may want to log on log_level INFO, but only send emails
when a log entry is WARN or more critical.


Wathcing the code for Exceptions
--------------------------------
You can watch your code for exceptions and then also log them. After you created your logmaster
instance, it's as simple as that:

    logmaster.watch_exceptions do
      1/0
    end

the exception will be rescued and logged as FATAL. If you also wish to actually raise it after it is
logged, don't forget to set `Logmaster#raise_exception` to `true`.
