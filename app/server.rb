require 'json'
require 'fileutils'
require 'pathname'
require_relative '../lib/newsletter'

module Server
  class Index
    HTML = File.read(File.expand_path('views/index.html', __dir__))

    def call(env)
      # TODO: use constant HTML
      html = File.read(File.expand_path('views/index.html', __dir__))
      [200, { 'Content-Type' => 'text/html' }, [html]]
    end
  end

  class Styles
    STYLES_DIR = Pathname.new(File.expand_path('../styles', __dir__)).freeze
    INVALID_RES = [400, { 'Content-Type' => 'application/json' }, ['{}']].freeze

    def call(env)
      req = Rack::Request.new(env)

      params = if req.post?
                 JSON.parse(req.body.read)
               else
                 req.params
               end

      name = params.fetch('name')
      path = File.join(STYLES_DIR, "#{name}.json")

      return INVALID_RES unless name.match?(/\A[a-z]+\Z/)

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
      INVALID_RES
    end
  end

  class SaveConfig
    NEWSLETTER_DIR = Pathname.new(File.expand_path('../newsletters', __dir__)).freeze

    def call(env)
      req = Rack::Request.new(env)

      params = JSON.parse(req.body.read)
      path = params.fetch('path')
      config = params.fetch('config')

      path = NEWSLETTER_DIR.join(path).to_s

      unless path.start_with?(NEWSLETTER_DIR.to_s)
        return [400, { 'Content-Type' => 'application/json' }, ['{}']]
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
