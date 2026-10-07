module Guidance
  class GuidancePage
    def initialize(path, template_dir:, content: nil)
      @path = path
      @template_dir = template_dir
      @content = content
    end

    def sections
      headings = page_contents.scan(/^##\s(.*)$/).map(&:first)

      headings.index_by { |heading| "##{heading.underscore.parameterize.gsub("_", "-")}" }
    end

    def template
      [template_dir, path].join("/")
    end

    def index_page?
      false
    end

  private

    attr_reader :path, :template_dir

    def page_contents
      @content || File.read(Rails.root.join("app", "views", "#{template}.md"))
    end
  end
end
