#!/bin/env ruby
# frozen_string_literal: true

require 'csv'
require 'pry'
require 'scraped'

require 'open-uri/cached'

class Legislature
  # details for an individual member
  class Member < Scraped::HTML
    field :id do
      url.split('=').last
    end

    PREFIXES = %w[Senator the Hon]
    SUFFIXES = %w[CSC DSC AO]

    field :name do
      SUFFIXES.reduce(unprefixed_name) { |current, suffix| current.sub(/#{suffix},?\s?$/, '').tidy }
    end

    field :party do
      noko.xpath('.//dt[text()="Party"]/following-sibling::dd[1]').text
    end

    field :constituency do
      noko.xpath('.//dt[text()="For"]/following-sibling::dd[1]').text
    end

    private

    def url
      noko.css('h4 a/@href').text
    end

    def full_name
      noko.css('h4').text.tidy
    end

    def unprefixed_name
      PREFIXES.reduce(full_name) { |current, prefix| current.sub("#{prefix} ", '') }
    end

  end

  # The page listing all the members
  class Members < Scraped::HTML
    decorator Scraped::Response::Decorator::CleanUrls

    field :members do
      noko.css('.search-filter-results .row').map { |mp| fragment(mp => Member).to_h }
    end
  end
end

urls = [
  'https://www.aph.gov.au/Senators_and_Members/Parliamentarian_Search_Results?q=&sen=1&par=-1&gen=0&ps=96'
]
data = urls.flat_map do |url|
  Legislature::Members.new(response: Scraped::Request.new(url: url).response).members
end

header = data.first.keys.to_csv
rows = data.map { |row| row.values.to_csv }
abort 'No results' if rows.count.zero?

puts header + rows.join
