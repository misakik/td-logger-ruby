module TreasureData
module Logger
module Agent::Rails

  CONFIG_PATH = 'config/treasure_data.yml'

  require 'td/logger/agent/rack'
  require 'td/logger/agent/rails/config'
  require 'td/logger/agent/rails/controller'
  #require 'td/logger/agent/rails/model'

  def self.init(rails)
    c = Config.init
    unless c
      ::TreasureData::Logger.open_null
      return false
    end

    if c.agent_mode?
      ::TreasureData::Logger.open_agent(c.tag, :host=>c.agent_host, :port=>c.agent_port)
    else
      ::TreasureData::Logger.open(c.database, :apikey=>c.apikey, :auto_create_table=>c.auto_create_table)
    end

    rails.middleware.use Agent::Rack::Hook

    Agent::Rack::Hook.before do |env|
      TreasureData::Logger.event.attribute.clear
    end

    Agent::Rails::ControllerExtension.init
    #Agent::Rails::AccessLogger.init(c.access_log_table) if c.access_log_enabled?
    #Agent::Rails::ModelExtension.init

    true
  end

  if ::Rails.respond_to?(:version) && ::Rails.version =~ /^3/
    class Railtie < ::Rails::Railtie
      initializer "treasure_data_logger.start_plugin" do |app|
        TreasureData::Logger::Agent::Rails.init(app.config)
      end
    end
  else
    TreasureData::Logger::Agent::Rails.init(::Rails.configuration)
  end

end
end
end
