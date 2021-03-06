module Crawl
  class Gods
    def initialize(god_abbrev_map)
      @god_abbrev_map = god_abbrev_map
    end

    def god_full_name(abbreviation)
      @god_abbrev_map[abbreviation]
    end

    def god_abbreviations
      @god_abbreviations ||= @god_abbrev_map.keys
    end

    def god_resolve_name(abbr)
      return unless abbr =~ /^[a-z]{2,}$/i

      dcabbr = abbr.downcase
      match = self.god_abbreviations.find { |g|
        full_name = self.god_full_name(g).downcase
        dcabbr.index(g) == 0 && (dcabbr == g || full_name.index(dcabbr) == 0)
      }
      match && self.god_full_name(match)
    end
  end
end
