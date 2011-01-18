module Import
  module ParseHelper
    def get_code row  
      code   = row.search("td[@class='g']").inner_text
      code[-code.size, 2]
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
  end  
end