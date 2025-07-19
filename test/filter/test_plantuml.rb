# ~*~ encoding: utf-8 ~*~
require File.expand_path(File.join(File.dirname(__FILE__), "..", "helper"))

context "Page" do

  setup do
    @wiki = Gollum::Wiki.new(testpath("examples/lotr.git"))
  end

  test "generate platuml img tags" do

    server_url = "http://localhost:8080/png"

    Gollum::Filter::PlantUML.configure do |config|
      config.test = true # Skip server checks
      config.url  = server_url # Non existent server
    end

    IMG_URLS = [
      "XP1D2i8m48NtESNGVIvGH4eHnNLFa9eVWkaCJ9A2jpUcBLWLNCvxtxpvwM9IdF8KnA0o4u8ymZNwe3EtSCi9h4TdMAmQoEAVZ78KMh2KKOD7O3yNP94hSQ4GyjH2J1GCMAP9B59rczw7aQ1NpdcCpGxxy1R-pAJVULVc8OmFqLFfyGm7AR-ffEw5ggaRzpEDJSgCHgyBxEtQCgZNBMhUc5B_YKeaEeEw_FK9",
      "SoWkIImgAStDuOfsJyn9J2dAJCs91R8pStJJGNmWspMdA3yFn70-lBOe9J4F99sObvAOanRBvP2QbmBI3000",
      "SoWkIImgAStDuN80iz8JyqfAk0gAyhDIaqkAanDpKXNAKrEpSogvejtpSt9ASsCLYb8BIpEBKeiL31LI4YkBkQATCdEIyf74ZQ3YRaNvASZYnX1nXzIy58Wr81R8QW00",
      "SoWkIImgISaiIKnKq7NbqjQ50Mq51NqOEqP1GG4ceyrLev3iv1Eg017JJdPqT8IoTRN3KekAC_FpQe1gOA06Z5mIInB1330ECmRI43NQKBk07AV4ubIeckGWLvVgb5gecfha03zlY3b0K5rSMuFc7gYn828690GIruVu1MQ-WWANGsfU2jYZ0000"
    ].map {|uri| "#{server_url}/#{uri}"}
  
    page = @wiki.page('RingBearers')

    doc = Nokogiri::HTML page.formatted_data

    img_tags = doc.css('img')
    assert img_tags.size == 4

    img_tags.each_with_index do |tag, i|
      assert tag.attribute("src").to_s == IMG_URLS[i]
    end
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
    assert error_tags.size == 4
  end

end
