require 'erb'

def render(template, binding = {})
  path = File.join(File.expand_path(File.dirname(__FILE__)), "../../templates/#{template}.erb")
  erb = ERB.new(File.read(path))
  erb.location = path
  erb.result_with_hash(binding)
end

def uri(base = "", **kwargs)
  URI(base).tap { |uri| uri.query = URI.encode_www_form kwargs }
end
