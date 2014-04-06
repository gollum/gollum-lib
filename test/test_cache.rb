require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

context "Cache" do
  setup do
    @cache = Gollum::Cache.new
  end

  test "write and read value" do
    @cache.write("key", "value")
    assert_equal "value", @cache.read("key")
  end

  test "write and read nil value" do
    @cache.write("key", nil)
    assert_equal nil, @cache.read("value")
  end

  test "cache if value is not write" do
    @cache.fetch("key") { "value" }
    assert_equal "value", @cache.read("key")
  end

  test "cache second time should return value" do
    @cache.fetch("key") { "value" }
    assert_equal "value", @cache.fetch("key") { raise("Cache shouldn't be accessed") }
  end
end
