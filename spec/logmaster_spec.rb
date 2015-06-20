require 'rspec'
require 'logmaster'
require 'fileutils'

class Logger
  # Suppress log messages when testing
  def add(*args);end
end

describe Logmaster do

  LOGFILE = File.expand_path(File.dirname(__FILE__) + '/logfile')

  before(:each) do
    # @logmaster = Logmaster.new(file: LOGFILE)
    @logmaster = Logmaster.new(
      file: LOGFILE,
      active_environments: 'development', 
      current_environment: 'development',
      sentry_config: { 
        "dsn" => 'https://c161fd9f6a0f42dcbfa1bee025cc493a:62d8b21cb6cd425ea4c3abb2cfbf76f7@app.getsentry.com/46218',
      }
    )
  end

  after(:each) do
    FileUtils.rm LOGFILE
  end

  it "creates two loggers (stdout and logfile)" do
    expect(@logmaster.loggers[0]).to be_kind_of(Logger) 
    expect(@logmaster.loggers[1]).to be_kind_of(Logger) 
  end

  it "sets email settings" do
    @logmaster.email_config = { to: 'your-email@here.com' } 
    expect(@logmaster.email_config).to eq({ via: :sendmail, from: 'logmaster@localhost', subject: "Logmaster message", to: 'your-email@here.com', :log_level=>:warn })
    expect(@logmaster.instance_variable_get(:@log_level)).to eq(Logger::WARN)
  end

  it "sends log messages to each logger" do
    @logmaster.loggers.each do |logger|
      expect(logger).to receive(:warn).once
    end
    @logmaster.warn("WARNING bitches!")
  end

  it "sends emails when the log level of a log message is appropriate" do
    @logmaster.email_config = { to: 'your-email@here.com', log_level: :warn } 

    expect(Pony).to receive(:mail).twice

    @logmaster.warn("WARNING bitches!") # Should call Pony.mail
    @logmaster.log_level = Logger::FATAL
    @logmaster.warn("WARNING bitches!") # This time shouldn't, log_level is wrong
  end

  it "watches for exceptions" do
    @logmaster.loggers.each do |logger|
      expect(logger).to receive(:fatal).once
    end
    @logmaster.watch_exceptions do
      1/0
    end
  end

  it "converts keys in the config settings hash into symbols (config.yml parsing makes them strings initially)" do
    @logmaster.email_config = { 'to' => 'your-email@here.com' }
    expect(@logmaster.email_config[:to]).not_to be_blank 
  end

end
