path = File.join(File.dirname(__FILE__), "..", "helper")
require File.expand_path(path)

context "Gollum::Filter::YAML" do
  setup do
    @page = mock_page
    @markup = Gollum::Markup.new(@page)
    @filter = Gollum::Filter::YAML.new(@markup)
  end

  def filter(content)
    @filter.process(@filter.extract(content))
  end

  test 'process yaml' do
    markup = <<~EOF
    ---
    Literal Scalar: |
      abc
      
      123
    Folded Scalar: >
      abc
      
      123
    Escaped: "abc\n\n123"
    ---

    # Markdown content here
    EOF

    result = {"Escaped"=> "abc\n" + "123",
      "Folded Scalar" => "abc\n" + "123\n",
      "Literal Scalar" => "abc\n" + "\n" + "123\n"
    }
        
    assert_equal "# Markdown content here\n", filter(markup)
    assert_nil @markup.metadata['errors']
    assert_equal result, @markup.metadata
  end

  test 'escape yaml' do
    markup = <<~EOF
    ---
    BadStuffInKey<script>bad()</script>: foo
    Literal Scalar: |
      <script>foo</script>
      
      123
    Folded Scalar: >
      >abc
      
      <123
    Escaped: "abc<script>123</script>"
    NestedBadStuff:
      Baz:
        - [1, "<script>bad()</script>"]
        - [1, 2, 3]
    ---

    # Markdown content here
    EOF

    result = {"Escaped"=> "abc",
      "Folded Scalar" => "&gt;abc\n" + "&lt;123\n",
      "Literal Scalar" => "\n" + "\n" + "123\n",
      "BadStuffInKey" => "foo",
      "NestedBadStuff"=> {"Baz"=>[[1, ""], [1, 2, 3]]}
    }
    filter(markup)   
    assert_nil @markup.metadata['errors']
    assert_equal result, @markup.metadata
  end
  
end