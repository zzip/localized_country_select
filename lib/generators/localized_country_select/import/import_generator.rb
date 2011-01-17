module LocalizedCountrySelect
  module Generators
    class ImportGenerator < Rails::Generators::Base
      desc "Import country locale files"

      argument      :locales,   :type => :array,  :default => [],     :desc => 'locales to generate for'
      class_option  :file_ext,  :type => :string, :default => 'yml',  :desc => 'file extension for locale files to import'

      source_root File.dirname(__FILE__)

      def main_flow
        raise ArgumentError, "File extension must be yml or rb" if ![:rb, :yml, :yaml].include?(file_ext.to_sym)
        check_hpricot
        import_locales
      end

      protected

      def file_ext        
        options[:file_ext]
      end

      def countries_yaml_content
        countries.inject([]) do |output, country|
          output << "\t\t\t#{country[:code]}: \"#{country[:name]}\""
          output
        end.join("\n")
      end

      def countries_hash_content
        countries.inject([]) do |output, country|
          output << "\t\t\t:#{country[:code]} => \"#{country[:name]}\","
          output
        end.join("\n")
      end

      def get_output file_ext
        send :"#{file_ext}_output"
      end

      def yaml_output
        output = %Q{
#{lang}:
  countries:
    #{countries_yaml_content}
}
      end

      def rb_output
        output = <<HASH
{ 
  :#{lang} => {
    :countries => {
      #{countries_hash_content}      
    }
  }
}
HASH
      end
      alias_method :yml_output, :yaml_output

      def check_hpricot
        begin
          require 'hpricot'
        rescue LoadError
          puts "Error: Hpricot library required to use this task (localized_country_select:import)"
          exit
        end
      end

      def import_locales
        # Check lang variable
        locales.each do |lang|
          import_locale lang
        end
      end

      def valid_lang? lang
        if lang == 'lang' || (/\A[a-z]{2}\z/).match(lang) == nil
          puts "\n[!] Usage: rails g localized_country_select:import de ru --file-ext yml\n\n"
          exit 0
        end
      end
      
      def import_locale lang
        valid_lang? lang
        # ----- Get the CLDR HTML     --------------------------------------------------
        begin
          puts "... getting the HTML file for locale '#{lang}'"
          doc = Hpricot( open("http://www.unicode.org/cldr/data/charts/summary/#{lang}.html") )
        rescue => e
          puts "[!] Invalid locale name '#{lang}'! Not found in CLDR (#{e})"
          exit 0
        end

        parse_languages doc
      end

      def parse_languages doc
        # ----- Parse the HTML with Hpricot     ----------------------------------------
        puts "... parsing the HTML file"
        countries = []
        doc.search("//tr").each do |row|
          next if !country_row? row
          countries << { :code => get_code(row).to_sym, :name => get_name(row).to_s }
        end
        generate_country_locales countries
      end

      def get_code row
        row.search("td[@class='g']").first.inner_text[-code.size, 2]
      end

      def get_name row
        row.search("td[@class='v']").first.inner_text
      end

      def country_row? row    
        row.search("td[@class='n']") && n_row?(row) && g_row?(row)           
      end

      def n_row? row
        row.search("td[@class='n']").inner_html =~ /^namesterritory$/
      end

      def g_row? row
        row.search("td[@class='g']").inner_html =~ /^[A-Z]{2}/
      end

      def generate_country_locales countries
        # ----- Prepare the output format  ------------------------------------------
        countries.each do |lang|
          write_locale_file lang
        end
      end

      def write_locale_file locale
        # ----- Write the parsed values into file   ---------------------------------
        puts "\n... writing the output"
        write_file locale
        puts "\n---\nWritten values for the '#{locale}' into file: #{filename}\n"
        # ------------------------------------------------------------------------------
      end    

      def write_file locale
        filename = File.join(Rails.root, 'config', 'locales', "countries.#{locale}.#{file_ext}")
        filename += '.NEW' if File.exists?(filename) # Append 'NEW' if file exists
        File.open(filename, 'w+') { |f| f << get_output(locale) }
      end      
    end
  end
end