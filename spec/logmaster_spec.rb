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
    @logmaster = Logmaster.new(file: LOGFILE)
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
    expect(@logmaster.email_config).to eq({ via: :sendmail, from: 'logmaster@localhost', subject: "Logmaster message", to: 'your-email@here.com' })
  end

  it "sends log messages to each logger" do
    @logmaster.loggers.each do |logger|
      expect(logger).to receive(:warn).once
    end
    @logmaster.warn("WARNING bitches!")
  end

  it "sends emails when the log level of a log message is appropriate" do
    @logmaster.email_config = { to: 'your-email@here.com' } 
    @logmaster.log_level = Logger::WARN

    expect(Pony).to receive(:mail)

    @logmaster.warn("WARNING bitches!") # Should call Pony.mail
    @logmaster.log_level = Logger::FATAL
    @logmaster.warn("WARNING bitches!") # This time shouldn't, log_level is wrong
  end

  it "watches for exceptions" do
    @logmaster.loggers.each do |logger|
      expect(logger).to receive(:fatal).once
    end
    @logmaster.watch_exceptions do
      raise "Lol what?"
    end
  end

end