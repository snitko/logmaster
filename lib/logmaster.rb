require 'logger'

class Logmaster

  attr_accessor :loggers, :log_level, :name, :email_config, :raise_exception, 
                :sentry_config, :active_environments, :current_environment, :email_log_level

  def initialize(
    log_level:       Logger::INFO,
    file:            nil,   # if nil, will not log into any file
    stdout:          true,  # if false, will not log into STDOUR
    raise_exception: false, # if true, will a raise an Exception after logging it
    email_config:    nil,   # see email config options for Pony gem
    name:            "Logmaster",
    sentry_config:   nil,
    active_environments: nil,
    current_environment: nil
  )
    @name            = name
    @raise_exception = raise_exception
    @log_level       = log_level
    @loggers         = []
    @active_environments = active_environments
    @current_environment = current_environment

    self.email_config = email_config if email_config
    @sentry_logger = initialize_sentry_logger(sentry_config) if sentry_config

    @loggers << ::Logger.new(STDOUT)            if stdout
    @loggers << ::Logger.new(file, 10, 1024000) if file
    @loggers.each { |l| l.level = @log_level }

  end

  def email_config=(settings)

    require 'pony'
    require 'erb'

    @email_config = { via: :sendmail, from: 'logmaster@localhost', subject: "#{@name} message", log_level: :warn }
    
    # Convert string keys into symbol keys
    settings = Hash[settings.map{|(k,v)| [k.to_sym,v]}]

    @email_config.merge!(settings)
    if @email_config[:to].nil?
      raise "Please specify email addresses of email recipients using :to key in email_config attr (value should be array)"
    end

    # Because pony doesn't like some arbitrary options like log_level
    # and instead of ignorning them, throws an error.
    @email_log_level = Logger.const_get(@email_config[:log_level].to_s.upcase)
    @email_config.delete(:log_level)

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
      if active_environments.include?(current_environment)

        if [:unknown, :fatal, :error, :warn, :info, :debug].include?(name)
          
          if @email_config && @email_log_level <= Logger.const_get(name.to_s.upcase)
            send_email(type: name, message: args[0]) 
          end

          if @email_config && @sentry_logger && @email_log_level <= Logger.const_get(name.to_s.upcase)
            send_email(type: name, message: args[0]) 
          end

          @loggers.each do |logger|
            logger.send(name, *args)
          end

        end
      end
    end

    def send_email(type:, message:)
      template = ERB.new(File.read(File.expand_path(File.dirname(__FILE__)) +
                         "/../email_templates/message.erb")
                         ).result(binding)

      Pony.mail(@email_config.merge({ html_body: template }))
    end

    def initialize_sentry_logger(sentry_config)
      begin
        require 'raven'
      rescue LoadError => e
        raise "You may need to install gem 'sentry-raven', :require => 'raven'"
      end
      Raven.configure do |config|
        config.dsn                 = sentry_config['dsn']
        config.excluded_exceptions = sentry_config['excluded_exceptions']
        config.environments        = active_environments
        config.silence_ready       = sentry_config['silence_ready']
      end
    end

end
