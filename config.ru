require ::File.expand_path('../config/environment', __FILE__)

# use Rails::Rack::Debugger
use Rack::ContentLength
run Rails.application
