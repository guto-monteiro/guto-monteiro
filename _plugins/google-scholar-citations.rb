require "active_support/all"
require "nokogiri"
require "open-uri"

module Helpers
  extend ActiveSupport::NumberHelper
end

module Jekyll
  class GoogleScholarCitationsTag < Liquid::Tag
    # Cache across renders in the same build process
    Citations = {}

    def initialize(tag_name, params, tokens)
      super
      splitted = params.split(" ").map(&:strip)
      @scholar_id = splitted[0]
      @article_id = splitted[1]

      if @scholar_id.nil? || @scholar_id.empty?
        puts "Invalid scholar_id provided"
      end

      if @article_id.nil? || @article_id.empty?
        puts "Invalid article_id provided"
      end
    end

    def render(context)
      article_id = context[@article_id.strip]
      scholar_id = context[@scholar_id.strip]

      # Defensive: if Liquid variables are missing, avoid blowing up
      if scholar_id.nil? || scholar_id.to_s.strip.empty?
        puts "Missing scholar_id in context for #{@scholar_id}"
        return "N/A"
      end

      if article_id.nil? || article_id.to_s.strip.empty?
        puts "Missing article_id in context for #{@article_id}"
        return "N/A"
      end

      article_id = article_id.to_s.strip
      scholar_id = scholar_id.to_s.strip

      article_url =
        "https://scholar.google.com/citations?view_op=view_citation&hl=en&user=#{scholar_id}&citation_for_view=#{scholar_id}:#{article_id}"

      begin
        # If the citation count has already been fetched, return it
        if GoogleScholarCitationsTag::Citations.key?(article_id)
          return GoogleScholarCitationsTag::Citations[article_id]
        end

        # Sleep for a random amount of time to avoid being blocked (longer helps)
        sleep(rand(8..15))

        # Fetch the article page with more realistic headers (Ruby/X.Y.Z often gets blocked)
        headers = {
          "User-Agent" =>
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
          "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
          "Accept-Language" => "en-US,en;q=0.9"
        }

        html = URI.open(article_url, headers).read
        doc  = Nokogiri::HTML(html)

        # Detect common Scholar block/captcha pages so you get a useful error
        page_title = doc.at("title")&.text.to_s.downcase
        if page_title.include?("sorry") || doc.at_css("form#gs_captcha_c, #captcha, input[name='captcha']")
          raise "Blocked by Google Scholar (captcha/robot check). Try building locally or caching results."
        end

        citation_count = 0

        # --- Attempt 1: extract from meta description tags ---
        meta = doc.at_css('meta[name="description"]') || doc.at_css('meta[property="og:description"]')
        if meta && meta["content"]
          m = meta["content"].match(/Cited by\s+([\d,]+)/)
          citation_count = m[1].delete(",").to_i if m
        end

        # --- Attempt 2: fallback to visible "Cited by N" link text ---
        if citation_count == 0
          cited_node = doc.at_xpath("//a[contains(normalize-space(.), 'Cited by')]")
          if cited_node
            m = cited_node.text.match(/Cited by\s+([\d,]+)/)
            citation_count = m[1].delete(",").to_i if m
          end
        end

        # Format for badge (0 will show as 0)
        citation_count = Helpers.number_to_human(
          citation_count,
          format: "%n%u",
          precision: 2,
          units: { thousand: "K", million: "M", billion: "B" }
        )

      rescue Exception => e
        citation_count = "N/A"
        puts "Error fetching citation count for #{article_id} in #{article_url}: #{e.class} - #{e.message}"
      end

      GoogleScholarCitationsTag::Citations[article_id] = citation_count
      "#{citation_count}"
    end
  end
end

Liquid::Template.register_tag("google_scholar_citations", Jekyll::GoogleScholarCitationsTag)
