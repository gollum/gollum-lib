# ~*~ encoding: utf-8 ~*~
require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

context "Page" do

  setup do
    @wiki = Gollum::Wiki.new(testpath("examples/lotr.git"))
  end

  test "generate platuml img tags" do

    FIRST_URL = "http://localhost:8080/plantuml/png/U9o5a4qAmZ0GXVSvnT1zBb14IX75TK-GcX-2wGnCaeAtDwOjM1LSpdlVlFdfObASyXJ4e38JWZp2DVgWCxTmomciHsTOh1h8uf-CSXHQi9HHWqTWFnTaaIjneH3or49C50nOfaaiKdMRteUHe5VEUOpD3llm5lxCfDzvL-OXZ0_HK-dn30SflwcaxeMggHltCurDoen6hmlixTeogDSjQjwOKl-9IYGwWxhyzGa9rdHb"

    SECOND_URL = "http://localhost:8080/plantuml/png/U9npA2v9B2efpStXYdPFp4bCASfCpOa5iZDpTDD1V23RDQSeFm_4S3wyjYWbCGyadPYNafYJ5ilba9gN0jGC08cq6OO0"

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
