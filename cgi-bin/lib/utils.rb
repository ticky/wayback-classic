require 'erb'

def render(template, binding = {})
  path = File.join(__dir__, "../../templates/#{template}.erb")
  erb = ERB.new(File.read(path))
  erb.location = path
  erb.result_with_hash(binding)
end

def uri(base = '', **kwargs)
  URI(base).tap do |uri|
    uri.query = URI.encode_www_form kwargs
  end
end

def number_formatter(number)
  number.to_s.gsub(/\B(?=(...)*\b)/, ',')
end

def pluralize(number, singular, plural)
  counter = if number.to_i == 1
              singular
            else
              plural
            end

  "#{number_formatter number.to_i} #{counter}"
end

def filesize(size)
  size = size.to_i

  units = %w[B KiB MiB GiB TiB Pib EiB ZiB]

  return '0.0 B' if size == 0

  exp = (Math.log(size) / Math.log(1024)).to_i
  exp += 1 if size.to_f / 1024**exp >= 1024 - 0.05
  exp = units.size - 1 if exp > units.size - 1

  format('%.0f %s', size.to_f / 1024**exp, units[exp])
end
