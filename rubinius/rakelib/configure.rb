def write_config_rb(path, config)
  FileUtils.mkdir_p File.dirname(path)
  File.open path, "wb" do |f|
    f.puts <<-EOC
module Rubinius
  config = {}
    EOC

    config.each do |k, v|
      f.puts "  config[:#{k}] = #{v.inspect}"
    end

    f.puts <<-EOC

  if Rubinius.constants.map { |x| x.to_s }.include?("BUILD_CONFIG")
    self::BUILD_CONFIG.replace config
  else
    self::BUILD_CONFIG = config
  end
end
    EOC
  end
end
