path = File.join(File.dirname(__FILE__), "..", "helper")
require File.expand_path(path)

context "Gollum::Filter::Code" do
  setup do
    @filter = Gollum::Filter::Code.new(Gollum::Markup.new(mock_page))
  end

  def filter(content)
    @filter.process(@filter.extract(content))
  end
  
  test 'mermaid language handler' do
    markup = <<~EOF
    # Some markup
    
    ```mermaid
    sequenceDiagram
      Alice->>John: Hello John, how are you?
      John-->>Alice: Great!
      Alice-)John: See you later!
    ```
    
    Foo
    EOF
    
    result = "# Some markup\n\n<div class=\"mermaid\">\nsequenceDiagram\n  Alice-&gt;&gt;John: Hello John, how are you?\n  John--&gt;&gt;Alice: Great!\n  Alice-)John: See you later!\n</div>\n\nFoo\n"
    
    assert filter(markup), result
  end
  
  
end