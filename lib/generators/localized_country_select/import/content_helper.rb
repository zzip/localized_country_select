module Import
  module ContentHelper
    def countries_yaml_content
      countries.inject([]) do |output, country|
        output << "    #{country[:code]}: \"#{country[:name]}\""
        output
      end.join("\n")
    end

    def countries_hash_content
      countries.inject([]) do |output, country|
        output << "    :#{country[:code]} => \"#{country[:name]}\","
        output
      end.join("\n")
    end

    def get_output
      send :"#{file_ext}_output"
    end

    def yaml_output
      output = %Q{#{locale}:
  countries:
#{countries_yaml_content}
}
    end

    def rb_output
      output = <<HASH
{ 
:#{locale} => {
  :countries => {
    #{countries_hash_content}      
  }
}
}
HASH
    end
    alias_method :yml_output, :yaml_output
  end
end