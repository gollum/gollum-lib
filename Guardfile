# ~*~ encoding: utf-8 ~*~
guard 'minitest' do
  # with Minitest::Unit
  watch(%r|^test/(.*)\/?test_(.*)\.rb|)
  watch(%r|^lib/(.*/)?([^/]+)\.rb|)     { |m| "test/test_#{m[2]}.rb" }
  watch(%r|^test/helper\.rb|)    { "test" }
end
