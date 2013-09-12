# ~*~ encoding: utf-8 ~*~
path = File.join(File.dirname(__FILE__), "helper")
require File.expand_path(path)

context "File" do
  setup do
    @wiki = Gollum::Wiki.new(testpath("examples/lotr.git"), { :repo_is_bare => true })
  end

  test "new file" do
    file = Gollum::File.new(@wiki)
    assert_nil file.raw_data
  end

  test "existing file" do
    commit = @wiki.repo.lookup(@wiki.repo.head.target)
    file   = @wiki.file("Mordor/todo.txt")
    assert_equal "[ ] Write section on Ents\n", file.raw_data
    assert_equal 'todo.txt',           file.name
    assert_equal commit.oid,           file.version.oid
    assert_equal commit.author[:name], file.version.author[:name]
  end

  test "accessing tree" do
    assert_nil @wiki.file("Mordor")
  end
end

context "File with checkout" do
  setup do
    @path = cloned_testpath("examples/lotr.git")
    @wiki = Gollum::Wiki.new(@path, { :repo_is_bare => false })
  end

  teardown do
    FileUtils.rm_rf(@path)
  end

  test "symbolic link" do
    file = @wiki.file("Data-Two.csv")

    assert_match /^FirstName,LastName\n/, file.raw_data
  end

  test "on disk file detection" do
    file = @wiki.file("Bilbo-Baggins.md", 'refs/heads/master', true)
    assert file.on_disk?
  end

  test "on disk file access" do
    file = @wiki.file("Bilbo-Baggins.md", 'refs/heads/master', true)
    path = file.on_disk_path

    assert ::File.exist?(path)
    assert_match /^# Bilbo Baggins\n\nBilbo Baggins/, IO.read(path)
  end

  # Removed this test:
  #
  # i think i'm just confused about what is happening here, but
  # here goes anyway.
  #
  # "Data-Two.csv" isn't a symbolic link, right?
  # It's *text* is the path that it wants to point to.
  #
  # test "symbolic link, with on-disk" do
  #   file = @wiki.file("Data-Two.csv", 'refs/heads/master', true)
  #
  #   assert file.on_disk?
  #   assert_match /Data\.csv$/, file.on_disk_path
  #   assert_match /^FirstName,LastName\n/, IO.read(file.on_disk_path)
  # end

  test "on disk file, with symlink, raw_data" do
    file = @wiki.file("Data-Two.csv")

    assert_match /^FirstName,LastName\n/, file.raw_data
  end
end

