module JavascriptHelper

  class Buffer
    include Singleton

    delegate :[], to: :@data

    def initialize
      clear!
    end

    def clear!
      @data = Hash.new{ |h,k| h[k] = "".html_safe }
    end
  end

  # the javascript block will be placed inside a jQuery(document).ready function
  def jquery_init(*args, &block)
    add_content(:jquery_init, *args, &block)
  end

  # the javascript block will be called after all the scripts have loaded
  def javascript_init(*args, &block)
    add_content(:javascript_init, *args, &block)
  end

  # You can LazyLoad more scripts through this method
  def javascript_content(*args, &block)
    add_content(:javascript_content, *args, &block)
  end

  def js_content_for(key)
    Buffer.instance[key]
  end

  def compressed_tinymce_url
    javascript_path("tinymce_packaged")
  end

  def jquery_path
    jquery_version = '1.7.2'

    if Rails.env.development?
      "jquery/#{jquery_version}/jquery-#{jquery_version}.js"
    else
      "//ajax.googleapis.com/ajax/libs/jquery/#{jquery_version}/jquery.min.js"
    end
  end

  def jquery_ui_path
    jquery_ui_version = '1.8.14'

    if Rails.env.development?
      "jquery-ui/#{jquery_ui_version}/jquery-ui.js"
    else
      "//ajax.googleapis.com/ajax/libs/jqueryui/#{jquery_ui_version}/jquery-ui.min.js"
    end
  end

  private

    # this should be the last method called as it returns a string to be properly returned into the page
    def add_content(target, *args, &block)
      content, options = extract_content_and_options(*args, &block)

      if options[:force] || request.xhr?# || in_iframe_ajax?
        javascript_tag(content)
      else
        Buffer.instance[target] << content
        ""
      end
    end

    # returns content and options
    def extract_content_and_options(*args, &block)
      options = args.extract_options!

      content = args.first || ""
      content = capture(&block) if block_given?

      [remove_script_and_cdata_tags(content), options]
    end

    def remove_script_and_cdata_tags(content)
      content.gsub(/^\s*<script[^>]*>(\s*\/\*\s*<!\[CDATA\[\s*\*\/)?/, "").gsub(/(\s*\/\*\s*\]\]\>\s*\*\/)?\s*<\/script>\s*$/, "").html_safe
    end
end
