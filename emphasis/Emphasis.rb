#!/usr/bin/env ruby
require "rubygems"

require "nokogiri"
require 'open-uri'
require 'pp'

require 'environment_variables.rb'

# Server side class for interpreting "emphasized" links in the same way in which the client side JavaScript does it. See: https://github.com/NYTimes/Emphasis
class Emphasis

  attr_reader :springer_html
  attr_reader :springer_dom

  TRANSFORMATION_FILE = 'xsl/transformation.xsl'

  def initialize()
    # css selector for the paragraphs
    @paragraph_selectors = "p"
  end

  # downloads the ID given as an argument
  # parses the returned data into an XML tree
  def load_springer_doc(springer_id)
    @springer_id = springer_id
    @springer_dom = Emphasis.fetch_springer_document(springer_id)

    # transform the article text from Springer A++ format into HTML
    xslt = Nokogiri::XSLT(open(TRANSFORMATION_FILE).read)
    @springer_html_dom = xslt.transform(@springer_dom)

    # create HTML dom just out of the content that would be displayed to the client
    # @springer_html_dom = Nokogiri::HTML(springer_html_plain)
    # pp @springer_html_dom
    # puts @springer_html_dom.css("p").size
  end

  # Highlight a Paragraph, or specific Sentences within it
  def goHighlight (h, s)
  #     if (!h) return
  #     hLen = h.size
  #
  #     for (var i=0; i<hLen; i++) {
  #         var para = this.paragraphList().list[h[i]-1] || false;
  #         if (para) {
  #             var sntns = s[h[i].toString()] || false;
  #             var multi = !sntns || sntns.length==0; #// Individual sentences, or whole paragraphy?
  #             var lines = this.getSentences(para);
  #             var jLen  = lines.length;
  #
  #         /*  First pass. Add SPAN tags to all lines. */
  #             for (var j=0; j<jLen; j++) {
  #                 var k = (multi) ? j : sntns[j]-1;
  #                 lines[j] = "<span data-num='" + (j+1) + "'>" + lines[j] + "</span>";
  #       # // lines[j] = "<a name='" + (j+1) + "' /><span data-num='" + (j+1) + "'>" + lines[j] + "</span>";
  #             }
  #
  #         /*  Second pass, update span to Highlight selected lines */
  #             for (var j=0; j<jLen; j++) {
  #                 var k    = (multi) ? j : sntns[j]-1;
  #                 var line = lines[k] || false;
  #                 if (line) {
  #                     lines[k] = lines[k].replace("<span", "<span class='" + this.classHighlight + "'");
  #         # // trying to create absolute links for sentences here
  #         # // lines[k] = lines[k].replace("<span", "<a name='" + + "'><span class='" + this.classHighlight + "'");
  #                 }
  #             }
  #
  #             para.setAttribute("data-sentences", jLen);
  #             para.innerHTML = lines.join('. ').replace(/__DOT__/g, ".").replace(/<\/span>\./g, ".<\/span>");
  #             para.addClassName('emReady'); /* Mark the paragraph as having SPANs */
  #         }
  #     }
  end


  # Read and interpret the URL hash
  def read_hash(lh)
    # lh => location hash
    # lh = decodeURI(location.hash);
    p  = false
    hi = false
    h = []
    s = {}

    # Version 2 of Emphasis (I am ignoring v1 here because I have not used it on the client side anyways)
    # #h[tbsaoa,Sstaoo,2,4],p[FWaadw] -> p = "FWaadw", h = [ "tbsaoa", "Sstaoo" ], s = { "Sstaoo" : [ 2, 4 ] }

    # findp = lh.match(/p\[([^[\]]*)\]/)
    # findh = lh.match(/h\[([^[\]]*)\]/)
    # p  = (findp && findp.length>0) ? findp[1] : false;
    # hi = (findh && findh.length>0) ? findh[1] : false;

    # SEB: strange. it looks like that there was an error in the javascript regexp here but it still works in js!!!
    if lh =~ /p\[([^\]]*)\]/
      p = $1
    end
    if lh =~ /h\[([^\]]*)\]/
      hi = $1
    end
    # puts p
    # puts hi

    # undef = nil
    # hi = nil

    highlightings = []

    if (hi)
        hi = hi.scan(/[a-zA-Z]+(?:,[0-9]+)*/)

        hi.each do |hi_element|
          a   = hi_element.split(',');
          key = a[0];
          # pos = this.find_key(key)['index']

          highlightings.push(find_key(key))

          # puts key
          # paragraph_for_key = find_key(key)
          # puts paragraph_for_key['index']
          # puts paragraph_for_key['elm'].to_html

          # if (pos != false) {
          #     h.push(parseInt(pos)+1);
          #     var b = a;
          #     b.shift();
          #     if (b.length>0) {
          #         for (var j=1; j<b.length; j++) {
          #             b[j] = parseInt(b[j]);
          #         }
          #     }
          #     s[h[h.length - 1]] = b;
          # }
          # break
      end
    end

    # @p = p;
    # @h = h;
    # @s = s;
    return highlightings
  end

  # From a list of Keys, locate the Key and corresponding Paragraph
  def find_key(key)
      pl = paragraph_list()
      ln = pl.keys.length
      ix = false
      el = false

      i = 0
      while i < pl["keys"].size
        if pl["keys"][i] == key
          return {
            "index" => i,
            "elm"   => pl["list"][i]
          }
        end
        i += 1
      end

      # for (var i=0;i<ln;i++) {
      #     if (key==pl.keys[i]) { // Direct Match
      #         return { index: i, elm: pl.list[i] };
      #     } else { // Look for 1st closest Match
      #         if (!ix) {
      #             var ls = this.lev(key.slice(0, 3), pl.keys[i].slice(0, 3));
      #             var le = this.lev(key.slice(-3)  , pl.keys[i].slice(-3));
      #             if ((ls+le)<3) {
      #                 ix = i;
      #                 el = pl.list[i];
      #             }
      #         }
      #     }
      # }

      return {
        "index" => ix,
        "elm"   => el
      }
  end

  # Build a list of Paragrphs, keys, and add meta-data to each Paragraph in DOM, saves list for later re-use
  def paragraph_list
      if (@pl)
        return @pl
      end

      # var instance = this;
      list = []
      keys = []
      # c    = 0
      # var len  = this.paraSelctors.length;

      # for (var p=0; p<len; p++) {
      paragraphs = @springer_html_dom.css(@paragraph_selectors)
      # puts paragraphs.size
      paragraphs.each do |pr|
        k = create_key(pr)
        list.push(pr)
        keys.push(k)
      end

          # var pr = this.paraSelctors[p];
          # if ((pr.innerText || pr.textContent || "").length>0) {
          #     var k = instance.createKey(pr);
          #     list.push(pr);
          #     keys.push(k);
          #     pr.setAttribute("data-key", k); // Unique Key
          #     pr.setAttribute("data-num", c); // Order
          #     Event.observe(pr, 'click', function(e) { instance.paragraphClick(e); }); // Prefer not doing this for each Paragraph but seemes nesesary
          #     c++;
          # }
      # }

      @pl = {
        "list" => list,
        "keys" => keys
      }
      return @pl
  end


  # From a Paragraph, generate a Key
  # p is a DOM node
  def create_key(p)
    key = ""
    len = 6 # this is the length of the key
    # txt = p.text.gsub(/[^a-z\. ]+/i, '');
    txt = p.text.gsub(/[^a-z\\. ]+/i, '');
    # txt = (p.innerText || p.textContent || '').replace(/[^a-z\. ]+/gi, '');
    if (txt && txt.length > 1)
      lines = get_sentences(txt)
      if (lines.size > 0)
        first = clean_array(lines[0].gsub(/[\s\s]+/i,' ').split(' ')).slice(0, (len/2))
        last  = clean_array(lines[lines.size-1].gsub(/[\s\s]+/i,' ').split(' ')).slice(0, (len/2))
        k = first + last #first.concat(last)

        key = k.map{|el| el.slice(0,1)}.join
      end
    end
    return key
  end

  # Break a Paragraph into Sentences, bearing in mind that the "." is not the definitive way to do so
  def get_sentences(html)
    # var html    = (typeof el=="string") ? el : el.innerHTML;

    # exclusion lists
    mrsList = "Mr,Ms,Mrs,Miss,Msr,Dr,Gov,Pres,Sen,Prof,Gen,Rep,St,Messrs,Col,Sr,Jf,Ph,Sgt,Mgr,Fr,Rev,No,Jr,Snr"
    topList = "A,B,C,D,E,F,G,H,I,J,K,L,M,m,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,etc,oz,cf,viz,sc,ca,Ave,St"
    geoList = "Calif,Mass,Penn,AK,AL,AR,AS,AZ,CA,CO,CT,DC,DE,FL,FM,GA,GU,HI,IA,ID,IL,IN,KS,KY,LA,MA,MD,ME,MH,MI,MN,MO,MP,MS,MT,NC,ND,NE,NH,NJ,NM,NV,NY,OH,OK,OR,PA,PR,PW,RI,SC,SD,TN,TX,UT,VA,VI,VT,WA,WI,WV,WY,AE,AA,AP,NYC,GB,IRL,IE,UK,GB,FR"
    numList = "0,1,2,3,4,5,6,7,8,9"
    webList = "aero,asia,biz,cat,com,coop,edu,gov,info,int,jobs,mil,mobi,museum,name,net,org,pro,tel,travel,xxx"
    extList = "www"
    d       = "__DOT__"

    # cleanup "." that should not be used for sentence splitting
    list = (topList+","+geoList+","+numList+","+extList)
    # html = html.replace(new RegExp((" "+list[i]+"\\."), "g"), (" "+list[i]+d))
    regexp = Regexp.new " (#{list.gsub(/,/,"|")})\\."
    html = html.gsub(regexp){|match| " #{match}#{d}"}
    # puts regexp.inspect

    list = (mrsList+","+numList)
    # html = html.replace(new RegExp((list[i]+"\\."), "g"), (list[i]+d))
    regexp = Regexp.new "(#{list.gsub(/,/,"|")})\\."
    html = html.gsub(regexp){|match| "#{match}#{d}"}

    list = webList
    # html = html.replace(new RegExp(("\\."+list[i]), "g"), (d+list[i]))
    regexp = Regexp.new "\\.(#{list.gsub(/,/,"|")})"
    html = html.gsub(regexp){|match| "#{d}#{match}"}

    # split sentences
    lines = clean_array(html.split('. '))
    return lines
  end

  # Remove empty items from an array
  def clean_array(a)
    a.select{|el| el.gsub(/\s/,"").size > 0}
  end

  # fetch the document with the given springer_id from the Springer API
  # convert it into an XML tree
  def self.fetch_springer_document(springer_id)
    url = "#{Springer_API_Endpoint}/app?q=doi:#{springer_id}&api_key=#{Springer_Openaccess}"
    puts "Query article: #{url}"
    doc = Nokogiri::XML(open(url).read)
    return doc
  end

end

