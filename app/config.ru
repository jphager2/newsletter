require 'rack'

require_relative 'server'

use Rack::Static, urls: %w[/css /js]

map '/' do
  run Server::Index.new
end

map '/config' do
  run Server::SaveConfig.new
end

map '/styles' do
  run Server::Styles.new
end

map '/render' do
  run Server::Render.new
end

map '/block' do
  run Server::Block.new
end
