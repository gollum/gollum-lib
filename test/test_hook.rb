# ~*~ encoding: utf-8 ~*~
path = File.join(File.dirname(__FILE__), 'helper')
require File.expand_path(path)

context 'Hook' do

  test 'registering a hook' do
    begin
      hook = Proc.new {}
      Gollum::Hook.register(:test, :hook, &hook)
      assert_same hook, Gollum::Hook.get(:test, :hook)
    ensure
      Gollum::Hook.unregister(:test, :hook)
    end
  end

  test 'reregistering a hook' do
    begin
      hook1 = Proc.new {}
      hook2 = Proc.new {}
      Gollum::Hook.register(:test, :hook, &hook1)
      Gollum::Hook.register(:test, :hook, &hook2)
      assert_same hook2, Gollum::Hook.get(:test, :hook)
    ensure
      Gollum::Hook.unregister(:test, :hook)
    end
  end

  test 'unregistering a hook' do
    begin
      hook = Proc.new {}
      Gollum::Hook.register(:test, :hook, &hook)
      Gollum::Hook.unregister(:test, :hook)
      assert_nil Gollum::Hook.get(:test, :hook)
    ensure
      Gollum::Hook.unregister(:test, :hook)
    end
  end

  test 'unregistering a non-existent hook' do
    Gollum::Hook.unregister(:test, :hook)
    assert_nil Gollum::Hook.get(:test, :hook)
  end

  test 'executing hooks' do
    begin
      received_args1 = received_args2 = nil
      hook1          = Proc.new { |*args| received_args1 = args }
      hook2          = Proc.new { |*args| received_args2 = args }
      Gollum::Hook.register(:test, :hook1, &hook1)
      Gollum::Hook.register(:test, :hook2, &hook2)
      args = [1, '2', :three]
      Gollum::Hook.execute(:test, *args)
      assert_equal args, received_args1
      assert_equal args, received_args2
    ensure
      Gollum::Hook.unregister(:test, :hook1)
      Gollum::Hook.unregister(:test, :hook2)
    end
  end

  test 'executing non-existent hooks' do
    begin
      received_args = nil
      hook          = Proc.new { |*args| received_args = args }
      Gollum::Hook.register(:test, :hook, &hook)
      args = [1, '2', :three]
      Gollum::Hook.execute(:test_non_existent, *args)
      assert_nil received_args
    ensure
      Gollum::Hook.unregister(:test, :hook)
    end
  end

end
