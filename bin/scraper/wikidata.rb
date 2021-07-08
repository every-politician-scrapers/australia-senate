#!/bin/env ruby
# frozen_string_literal: true

require_relative '../../lib/wikidata_query'

# TODO: Add party
query = <<SPARQL
  SELECT (STRAFTER(STR(?item), STR(wd:)) AS ?wdid) ?name ?state
  WHERE {
    ?item p:P39 ?ps .
    ?ps ps:P39 wd:Q6814428 ; pq:P580 ?start .
    OPTIONAL { ?ps pq:P582 ?end }
    FILTER(!BOUND(?end) || ?end > NOW())

    OPTIONAL {
      ?ps pq:P768 ?district .
      OPTIONAL { ?district rdfs:label ?state FILTER(LANG(?state) = "en") }
    }

    OPTIONAL { ?ps prov:wasDerivedFrom/pr:P1810 ?sourceName }
    OPTIONAL { ?item rdfs:label ?enLabel FILTER(LANG(?enLabel) = "en") }
    BIND(COALESCE(?sourceName, ?enLabel) AS ?name)
  }
  ORDER BY ?name
SPARQL

puts WikidataQuery.new(query, 'every-politican-scrapers/australia-senate').csv
