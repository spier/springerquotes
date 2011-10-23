#!/usr/bin/env ruby
require "rubygems"
require "bundler/setup" # from http://gembundler.com/rationale.html

# normal requires (these are no gems but part of ruby core. Or not?)
require 'open-uri'
require 'pp'
require 'cgi'

require 'sinatra/base'
require "nokogiri"
require "json"
require "i18n"
require "curb"

# ------------------------------------------------------------------

# My YQL gem
require "yql_simple"

# Own Dependencies
require 'environment_variables.rb'

require 'QuotedArticle.rb'
require 'Couch.rb'
require 'emphasis/Emphasis.rb'

# Globals
MAX_PAGES           = 10  # the maximum number of pages to show when paginating
PAGE_SIZE           = 10  # articles per page
DEFAULT_START_INDEX = 1   # index from where to start when no start index is specified

# ------------------------------------------------------------------

class App < Sinatra::Base
  # Sinatra settings
  set :root, File.dirname(__FILE__)

  not_found do
    erb :'404'
  end

  error do
    erb :'500'
  end

  # home page
  get '/' do
    # retrieve the previously stored documents
    @last_articles_highlighted = couch_read_quotes()

    # get click statistics from bit.ly
    # @click_stats = get_bitly_click_stats(@last_articles_highlighted)

    erb :index
  end

  # search for articles
  get '/search' do
    @search_terms = params["search_terms"]
    puts "Search terms entered: #{@search_terms}"

    @search_results = {}
    @start_index = params["s"].nil? ? DEFAULT_START_INDEX : params["s"].to_i

    # run search
    if !@search_terms.nil? and @search_terms != ""
      url = "#{Springer_API_Endpoint}/json?q=#{CGI.escape(@search_terms)}&s=#{@start_index}&p=#{PAGE_SIZE}&api_key=#{Springer_Openaccess}"
      puts "Searching Springer: #{url}"
      @search_results = JSON.parse(open(url).read)
      puts "Articles found: #{@search_results["result"][0]["total"]}"

      # save the search
      couch_save_search(@search_terms,@search_results["result"][0]["total"].to_i)

      erb :search_results
    else
      redirect '/'
    end
  end

  # show one article
  get '/article/*' do
    @springer_id = params[:splat]
    # API call for article data
    url = "#{Springer_API_Endpoint}/app?q=doi:#{@springer_id}&api_key=#{Springer_Openaccess}"
    puts "Query article: #{url}"
    doc = Nokogiri::XML(open(url).read)

    # test for writing the doc that comes back to disk
    # open("test.xml",'w') do |f|
    #   f.puts doc.to_xml
    # end

    @title = doc.xpath("//Article/ArticleInfo/ArticleTitle").text()

    # transform the article text from Springer A++ format into HTML
    xslt = Nokogiri::XSLT(open('xsl/transformation.xsl').read)
    @body = xslt.transform(doc)

    # remove the leading <?xml version="1.0"?>
    @body = @body.to_xml()
    @body = @body.gsub(/<\?xml version="1\.0"\?>/,"")

    erb :show_article
  end

  # show one article
  # get %r{/showquote/(.*?)#(.*)} do
  get '/quotes/*' do
    @springer_id = params[:splat][0]

    # springer_id = 'doi:10.1007/s12052-008-0061-8'
    emph = Emphasis.new
    emph.load_springer_doc(@springer_id)

    @title = emph.springer_dom.xpath("//Article/ArticleInfo/ArticleTitle").text()
    @highlightings = emph.read_hash(params["quotes"])

    # get teaser version of document to show together with the quotes
    xslt = Nokogiri::XSLT(open('xsl/transformation_quotes.xsl').read)
    @body = xslt.transform(emph.springer_dom)

    # remove the leading <?xml version="1.0"?>
    @body = @body.to_xml()
    @body = @body.gsub(/<\?xml version="1\.0"\?>/,"")

    erb :show_quotes
  end

  # create a shortened link of the given article link, using bit.ly.
  # also store an entry in CouchDB
  post '/shorten' do
    # read params
    long_url = params["longUrl"]
    title = params["title"]
    springer_id = params["springer_id"]
    puts "Creating bitly URL for '#{title}' (#{long_url})"

    # create a shortenend URL
    short_url = shorten_with_bitly(long_url)
    puts "Short URL created: #{short_url}"

    # save the document
    # insertion_status = save_highlighted_document(title,long_url,short_url,springer_id)
    # puts "Insertion successful? : #{insertion_status}"
    couch_save_quote(title,long_url,short_url,springer_id)

    return JSON.generate( {:short_url => short_url} )
  end

  # read all documents out of /quotes
  def couch_read_quotes(limit = 5)
    server = Couch::Server.new(Couchdb_server, Couchdb_server_port, Couchdb_user, Couchdb_password)
    response = server.get("#{Couchdb_db_path}/_design/quotes/_view/sortedByDate?include_docs=true&descending=true&limit=#{limit}")
    # response = server.get("#{Couchdb_db_path}/_all_docs?include_docs=true&limit=#{limit}")
    response = JSON.parse(response.body)

    # read all documents and create a QuotedArticle for them
    docs = response["rows"].map do |d|
      # d["doc"]
      QuotedArticle.new(d["doc"])
    end

    return docs
  end

  # save one document to couchDB
  def couch_save_quote(title,long_url,short_url,springer_id)
    # extract just the highlightings out of the full URL of the article page
    uri_parts = URI.split(long_url)
    highlightings = uri_parts[8]

    # create the document for CouchDB
    doc = QuotedArticle.new(
      :title => title,
      :url => long_url,
      :short_url => short_url,
      :springer_id => springer_id,
      :highlightings => highlightings,
      :clicks => 0
    )

    # connect to couch and insert document
    server = Couch::Server.new(Couchdb_server, Couchdb_server_port, Couchdb_user, Couchdb_password)

    # http://flori.github.com/json/
    # fast_generate can be used if there are no recursive structures below (read that somewhere in the documentation)
    response = server.post(Couchdb_db_path, JSON.fast_generate(doc))
    pp JSON.parse(response.body)
  end

  def couch_save_search(search, article_count)
    # create the document for CouchDB
    doc = {
      :search => search,
      :articles_found => article_count,
      :created_at => Time.now.strftime("%Y/%m/%d %H:%M:%S %z")
    }

    # connect to couch and insert document
    server = Couch::Server.new(Couchdb_server, Couchdb_server_port, Couchdb_user, Couchdb_password)

    # fast_generate can be used if there are no recursive structures below (read that somewhere in the documentation)
    response = server.post("/searches", JSON.fast_generate(doc))
  end


  # shorten the given long_url with bit.ly
  def shorten_with_bitly(long_url)
    # long URL will be sth like:
    # http://springerquotes.heroku.com/article/doi:10.1186/1477-7819-1-29#h[AtmWaa,7,AraRwg,13,IatDaw,1,GcoNwm,4]

    # generate the quote URL like this:
    # http://springerquotes.heroku.com/quotes/doi:10.1186/1471-2105-7-126?quotes=h[TmeWta,2,5,6,witFas,2]
    # ["http",
    #  nil,
    #  "localhost",
    #  "9292",
    #  nil,
    #  "/article/doi:10.1186/1471-2105-7-126",
    #  nil,
    #  nil,
    #  "h[TmeWta,2,5,6,witFas,2]"]
    uri_elements = URI.split(long_url)
    quote_url = "http://springerquotes.heroku.com/#{uri_elements[5].gsub(/^\/article/,"quotes")}?quotes=#{uri_elements[8]}"

    puts "Creating bit.ly URL for #{quote_url}"

    # shorten URL
    yql_query = "
      SET login = '#{Bitly_username}' ON bit.ly;
      SET apiKey = '#{Bitly_apikey}' ON bit.ly;
      SELECT data FROM bit.ly.shorten WHERE longUrl='#{quote_url}';
    "
    yql_query = YqlSimple.query(yql_query)

    begin
      short_url = yql_query["query"]["results"]["response"]["data"]["url"]
    rescue Exception => ex
      short_url = nil
    end

    return short_url
  end

  # def get_bitly_click_stats(articles)
  #   #
  #   # fill the click_stats with 0
  #   #
  #   click_stats = {}
  #   articles.each do |article|
  #     click_stats[article.short_url] = 0
  #   end
  #
  #   #
  #   # query current click stats from bitly
  #   #
  #   yql_query = "
  #     SET login = '#{Bitly_username}' ON bit.ly;
  #     SET apiKey = '#{Bitly_apikey}' ON bit.ly;
  #     SELECT data.clicks.short_url,data.clicks.global_clicks FROM bit.ly.clicks WHERE shortUrl IN (#{@last_articles_highlighted.map{|e| "'#{e.short_url}'"}.join(",")})
  #   "
  #   # yql_query = execute_yql_query(yql_query)
  #   # replace this with YqlSimple
  #
  #   begin
  #     click_stats = yql_query["query"]["results"]["json"]
  #     click_stats = click_stats.map{|e| [ e["data"]["clicks"]["short_url"],e["data"]["clicks"]["global_clicks"] ]}
  #     click_stats = Hash[click_stats]
  #   rescue Exception => ex
  #     puts ex
  #     click_stats = {}
  #   end
  #
  #   return click_stats
  # end

end


# if this app is run outside rack
if __FILE__ == $0
  App.run!
end