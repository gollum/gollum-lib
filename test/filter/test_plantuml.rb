# ~*~ encoding: utf-8 ~*~
require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

context "Page" do

  setup do
    @wiki = Gollum::Wiki.new(testpath("examples/lotr.git"))
  end

  test "generate platuml img tags" do

    FIRST_URL = "http://localhost:8080/plantuml/png/XP1D2i8m48NtESNGVIvGH4eHnNLFa9eVWkaCJ9A2jpUcBLWLNCvxtxpvwM9IdF8KnA0o4u8ymZNwe3EtSCi9h4TdMAmQoEAVZ78KMh2KKOD7O3yNP94hSQ4GyjH2J1GCMAP9B59rczw7aQ1NpdcCpGxxy1R-pAJVULVc8OmFqLFfyGm7AR-ffEw5ggaRzpEDJSgCHgyBxEtQCgZNBMhUc5B_YKeaEeEw_FK9"

    SECOND_URL = "http://localhost:8080/plantuml/png/SoWkIImgAStDuOfsJyn9J2dAJCs91R8pStJJGNmWspMdA3yFn70-lBOe9J4F99sObvAOanRBvP2QbmBK3000"

    Gollum::Filter::PlantUML.configure do |config|
      config.test = true # Skip server checks
      config.url  = "http://localhost:8080/plantuml/png" # Non existent server
    end

    page = @wiki.page('RingBearers')

    doc = Nokogiri::HTML page.formatted_data

    img_tags = doc.css('img')

    assert img_tags.size == 2
    assert img_tags[0].attribute("src").to_s == FIRST_URL, img_tags[0].inspect
    assert img_tags[1].attribute("src").to_s == SECOND_URL, img_tags[1].inspect
  end

  test "generate errors when server unavailable" do

    Gollum::Filter::PlantUML.configure do |config|
      config.test = false # Ensure we check for server availability
      config.url  = "http://localhost:0000/plantuml/png" # Non existent server
    end

    page = @wiki.page('RingBearers')

    doc = Nokogiri::HTML page.formatted_data

    img_tags = doc.css('img')
    error_tags = doc.css('.gollum-error')

    assert img_tags.size == 0
    assert error_tags.size == 2
  end

end
