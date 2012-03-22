ENV['RAILS_ENV'] ||= 'production'

RAILS_GEM_VERSION = '2.3.8' unless defined? RAILS_GEM_VERSION

require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  
  config.gem 'authlogic',
             :version => '~> 2.1.0'
  config.gem 'haml',
             :version => '~> 2.0.9'
  config.gem "will_paginate", :source => "http://gems.github.com"
  config.gem 'mime-types', :lib => 'mime/types'

  config.active_record.default_timezone = 'Prague'
  
  config.i18n.load_path = Dir[File.join(RAILS_ROOT, 'config', 'locales', '*.{rb,yml}')]
  config.i18n.default_locale = :cz
 
  %w(middleware).each do |dir|
    config.load_paths << "#{Rails.root.to_s}/app/#{dir}"
  end
  
  config.action_controller.cache_store = :file_store, "/tmp/cache"
  config.action_controller.session_store = :active_record_store
end

require 'will_paginate'
require "pry"
Pry.start

$KCODE = 'u' #$KCODE = 'UTF8'
require 'jcode'

ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.default_charset = "utf-8"
ActionMailer::Base.raise_delivery_errors = true
ActionMailer::Base.smtp_settings = {
 :address => "localhost",
 :port => 25,
 :domain => "localhost"
}

ActiveRecord::Base.logger.level = 0 # 0=debug, 1=info
