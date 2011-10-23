require 'Emphasis'
require 'nokogiri'

describe Emphasis do

  describe "get_sentences()" do
    it "returns 3 for split" do
      emphasis = Emphasis.new

      text = "At the outset, we noted that understanding certain science themes could be especially relevant for accepting evolution. In particular, we noted the importance of understanding the status of theories and of appreciating that testing empirical hypotheses can involve complex inferences and methods. This suggests that the themes we have labeled as ‘theory support,’ ‘theory limits,’ ‘testing,’ ‘non-linearity,’ and ‘construction’ should correlate with accepting evolution."
      sentences = emphasis.get_sentences(text)

      sentences.size.should eql(3)
    end

    it "Mr and Mrs" do
      emphasis = Emphasis.new

      text = "Mr. Smith is the best. Mrs. Smith is not my favourite."
      sentences = emphasis.get_sentences(text)

      sentences.size.should eql(2)
    end
  end

  describe "create_key()" do
    it "returns FtoEip" do
      paragraph = "<p>Fewer than 50% of Americans accept Darwin’s theory of evolution by natural selection (Miller et al. 2006), a statistic considerably at odds with the overwhelming support for evolution in most industrialized nations and within the scientific community (Miller et al. 2006; AAAS 2006; NAS 2008a, b). Evolution informs practice and progress in areas from medicine and biotechnology to environmental policy and public health, which makes the widespread rejection of evolution a serious public concern.</p>"
      paragraph = Nokogiri.HTML(paragraph)
      paragraph = paragraph.css("p")[0]

      emphasis = Emphasis.new
      key = emphasis.create_key(paragraph)
      key.should eql("FtoEip")
    end
  end

end