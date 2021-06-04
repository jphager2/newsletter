require 'json'
require 'fileutils'
require 'pathname'
require_relative '../lib/newsletter'

module Server
  def self.root=(path)
    @root = Pathname.new(path)
  end

  def self.root
    @root ||= Pathname.new(Dir.pwd)
  end

  class Index
    HTML = File.read(File.expand_path('views/index.html', __dir__))

    def call(env)
      # TODO: use constant HTML
      html = File.read(File.expand_path('views/index.html', __dir__))
      [200, { 'Content-Type' => 'text/html' }, [html]]
    end
  end

  class Styles
    def call(env)
      req = Rack::Request.new(env)

      params = if req.post?
                 JSON.parse(req.body.read)
               else
                 req.params
               end

      path = params.fetch('path')
      path = Server.root.join(path).expand_path

      unless path.to_s.start_with?(Server.root.to_s) && path.exist?
        return [
          400,
          { 'Content-Type' => 'application/json' },
          ["{\"error\": Path not found: #{path}}"]
        ]
      end

      if req.post?
        styles = params.fetch('styles')
        File.write(path, JSON.pretty_generate(styles))

        [201, { 'Content-Type' => 'application/json' }, []]
      else
        json = File.read(path)
        [200, { 'Content-Type' => 'application/json' }, [json]]
      end
    rescue KeyError, JSON::ParserError => e
      pp e
      [400, { 'Content-Type' => 'application/json' }, ['{}']]
    end
  end

  class SaveConfig
    def call(env)
      req = Rack::Request.new(env)

      params = JSON.parse(req.body.read)
      config = params.fetch('config')

      path = params.fetch('path')
      path = Server.root.join(path).expand_path

      unless path.to_s.start_with?(Server.root.to_s)
        return [
          400,
          { 'Content-Type' => 'application/json' },
          ["{\"error\": Path not found: #{path}}"]
        ]
      end

      FileUtils.mkdir_p(path)
      File.write(File.join(path, 'source.json'), JSON.pretty_generate(config))

      [201, { 'Content-Type' => 'application/json' }, []]
    rescue KeyError, JSON::ParserError => e
      pp e
      [400, { 'Content-Type' => 'application/json' }, ['{}']]
    end
  end

  class Render
    def call(env)
      req = Rack::Request.new(env)

      params = JSON.parse(req.body.read)
      newsletter = Newsletter.render(params['config'], params['styles'])

      json = { html: newsletter.to_html, markdown: newsletter.to_markdown }.to_json

      [200, { 'Content-Type' => 'application/json' }, [json]]
    rescue JSON::ParserError => e
      pp e
      [400, { 'Content-Type' => 'application/json' }, ['{}']]
    end
  end

  class Block
    def call(env)
      req = Rack::Request.new(env)

      block = Newsletter.block({ 'type' => req.params['type'] }, {})

      unless block
        [400, { 'Content-Type' => 'application/json' }, ['{}']]
      end


      [200, { 'Content-Type' => 'application/json' }, [block.to_json]]
    rescue JSON::ParserError => e
      pp e
    end
  end
end
