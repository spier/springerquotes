#!/usr/bin/env ruby
require "rubygems"
require 'time'

class QuotedArticle
  # properties created by couchDB (taken from CouchPotato)
  attr_accessor :_id
  attr_accessor :_rev
  attr_accessor :_deleted

  # own properties
  attr_accessor :title
  attr_accessor :url
  attr_accessor :short_url
  attr_accessor :springer_id
  attr_accessor :highlightings
  attr_accessor :clicks
  attr_accessor :created_at

  # initialize a new instance of this Class with the given attributes
  # TODO: this comes from CouchPotato.
  def initialize(attributes = {})
    # use the current time as a creation time.
    # if a time is set in the attributes hash, then this time will be overwritten
    @created_at = Time.now.strftime("%Y/%m/%d %H:%M:%S")

    # set all attributes from the attributes hash
    if attributes
      attributes.each do |name, value|
        self.send("#{name}=", value)
      end
    end
    yield self if block_given?
  end

  # it trying to set the created_at field with a string argument, convert it to a time (coming from Couch)
  def created_at=(val)
    if val.is_a?(String)
      @created_at = Time.parse(val)
    else
      @created_at = val
    end
  end

  # return the qrcode of bitly for this document
  # wrap this, so that I could more easily change this if I should ever decide to generate my qrcodes differently
  def qrcode
    "#{self.short_url}.qrcode"
  end

  # a shortened version of the title that fits the article listing in route /
  def shortened_title
    if title.size < 120
      return title
    else
      return "#{title.slice(0,120)}..."
    end
  end

  # serialize object to JSON
  def to_json(*a)
    {
      'title'         => @title,
      'url'           => @url,
      'short_url'     => @short_url,
      'springer_id'   => @springer_id,
      'highlightings' => @highlightings,
      'clicks'        => @clicks,
      'created_at'    => @created_at,
    }.to_json(*a)
  end

end