require 'json'

module Newsletter
  def self.render(config, styles)
    markdown = []
    html = []

    config['blocks'].each do |block_config|
      block = Newsletter.block(block_config, styles)

      next unless block

      markdown << block.to_markdown
      html << block.to_html
    end

    Body.new({ 'markdown' => markdown, 'html' => html }, styles)
  end

  def self.block(config, styles)
    block_class = TYPES[config['type']]

    return unless block_class

    block_class.new(config, styles)
  end

  class Block
    attr_reader :styles

    def initialize(config, styles)
      @config = config
      @styles = styles
    end

    def cell_style
      styles['td']
    end

    def block_html
      <<~HTML
        <table width="100%">
          <tr>
            <td style=\"#{cell_style}\">
              #{yield.gsub("\n", "\n" + ' ' * 6 ).rstrip}
            </td>
          </tr>
        </table>
      HTML
    end

    def to_json
      {
        type: nil,
        text: nil,
        data: {}
      }.to_json
    end
  end

  class Title < Block
    attr_reader :title, :subtitle

    def initialize(config, styles)
      super

      @title = config['text']
      @subtitle = config.dig('data', 'subtitle')
    end

    def title_style
      styles['.title']
    end

    def subtitle_style
      styles['.subtitle']
    end

    def to_markdown
      markdown = "# #{title}"
      markdown << "\n\n#{subtitle}" if subtitle
      markdown
    end

    def to_html
      block_html do
        html = "<h1 style=\"#{title_style}\">#{title}</h1>"
        html << "\n<p style=\"#{subtitle_style}\">#{subtitle}</p>" if subtitle
        html
      end
    end

    def to_json
      {
        type: 'title',
        text: title,
        data: {
          subtitle: subtitle
        }
      }.to_json
    end
  end

  class Quote < Block
    attr_reader :quote

    def initialize(config, styles)
      super

      @quote = config['text'].to_s
    end

    def style
      styles['.quote']
    end

    def to_markdown
      "> #{quote.gsub("\n", "\n> ")}"
    end

    def to_html
      block_html do
        "<blockquote style=\"#{style}\">#{quote.gsub("\n", '<br>')}</blockquote>"
      end
    end

    def to_json
      {
        type: 'quote',
        text: quote
      }.to_json
    end
  end

  class Header < Block
    attr_reader :header

    def initialize(config, styles)
      super

      @header = config['text']
    end

    def style
      styles['.header']
    end

    def to_markdown
      "## #{header}"
    end

    def to_html
      block_html do
        "<h2 style=\"#{style}\">#{header}</h2>"
      end
    end

    def to_json
      {
        type: 'header',
        text: header
      }.to_json
    end
  end

  class Link < Block
    attr_reader :title, :href, :description

    def initialize(config, styles)
      super

      @title = config['text']
      @href = config.dig('data', 'href')
      @description = config.dig('data', 'description')
    end

    def title_style
      styles['.link--title']
    end

    def link_style
      styles['.link--anchor']
    end

    def description_style
      styles['.link--description']
    end

    def to_markdown
      "### [#{title}](#{href})\n\n#{description}"
    end

    def to_html
      block_html do
        <<~HTML
          <h3 style="#{title_style}"><a style="#{link_style}" href="#{href}">#{title}</a></h3>
          <p style="#{description_style}">#{description}</p>
        HTML
      end
    end

    def to_json
      {
        type: 'link',
        text: title,
        data: {
          href: href,
          description: description
        }
      }.to_json
    end
  end

  class Image < Block
    attr_reader :alt, :src

    def initialize(config, styles)
      super

      @alt = config['text']
      @src = config.dig('data', 'href')
    end

    def style
      styles['.image']
    end

    def to_markdown
      "![#{alt}](#{src})"
    end

    def to_html
      block_html do
        "<img style=\"#{style}\" alt=\"#{alt}\" src=\"#{src}\">"
      end
    end

    def to_json
      {
        type: 'image',
        text: alt,
        data: {
          href: src
        }
      }.to_json
    end
  end

  class Text < Block
    attr_reader :text

    def initialize(config, styles)
      super

      @text = config['text']
    end

    def style
      styles['.text']
    end

    def to_markdown
      text
    end

    def to_html
      block_html do
        text.split(/\n+/).map do |para|
          "<p style=\"#{style}\">#{para}</p>"
        end.join("\n")
      end
    end

    def to_json
      {
        type: 'text',
        text: text
      }.to_json
    end
  end

  class Body
    attr_reader :markdown, :html, :styles

    def initialize(config, styles)
      @styles = styles

      @markdown = config['markdown'].join("\n\n")
      @html = config['html'].join("\n")
    end

    def to_markdown
      markdown
    end

    def body_style
      styles['body']
    end

    def table_style
      styles['table']
    end

    def to_html
      <<~HTML
        <!doctype html>
        <html>
          <head>
          </head>
          <body style="height: 100%">
            <div style="height: 100%;#{body_style}">
              <table width="100%" align="center" style="height: 100%;#{table_style};padding-bottom: 30px;">
                <tr>
                  <td align="center">
                     #{html.gsub("\n", "\n            ").rstrip}
                  </td>
                </tr>
              </table>
            </div>
          </body>
        </html>
      HTML
    end
  end

  TYPES = {
    'title' => Title,
    'quote' => Quote,
    'header' => Header,
    'link' => Link,
    'image' => Image,
    'text' => Text,
  }.freeze
end
