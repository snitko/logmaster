require 'logger'

class Logmaster

  attr_accessor :loggers, :log_level, :name, :email_config, :raise_exception

  def initialize(
    log_level:       Logger::INFO,
    file:            nil,   # if nil, will not log into any file
    stdout:          true,  # if false, will not log into STDOUR
    raise_exception: false, # if true, will a raise an Exception after logging it
    email_config:    nil,   # see email config options for Pony gem
    name:            "Logmaster"
  )

    @name            = name
    @raise_exception = raise_exception
    @log_level       = log_level
    @loggers         = []

    self.email_config = email_config if email_config

    @loggers << ::Logger.new(STDOUT)            if stdout
    @loggers << ::Logger.new(file, 10, 1024000) if file
    @loggers.each { |l| l.level = @log_level }

  end

  def email_config=(settings)

    require 'pony'
    require 'erb'

    @email_config = { via: :sendmail, from: 'logmaster@localhost', subject: "#{@name} message" }
    @email_config.merge!(settings)
    if @email_config[:to].nil?
      raise "Please specify email addresses of email recipients using :to key in email_config attr (value should be array)"
    end

  end

  def watch_exceptions
    raise "Please provide a block to this method" unless block_given?
    begin
      yield
    rescue Exception => e
      message =  e.class.to_s
      message += ": "
      message += e.message
      message += "\n"
      message += "Backtrace:\n"
      e.backtrace.each { |l| message += "    #{l}\n" }
      self.fatal(message)
      raise e if @raise_exception
    end
  end

  private

    def method_missing(name, *args)

      if [:unknown, :fatal, :error, :warn, :info, :debug].include?(name)
        
        if @email_config && @log_level <= Logger.const_get(name.to_s.upcase)
          send_email(type: name, message: args[0]) 
        end

        args[0] = args[0] + "\n\n"
        @loggers.each do |logger|
          logger.send(name, *args)
        end

      end

    end

    def send_email(type:, message:)
      template = ERB.new(File.read(File.expand_path(File.dirname(__FILE__)) +
                         "/../email_templates/message.erb")
                         ).result(binding)

      Pony.mail(@email_config.merge({ html_body: template }))
    end


end
