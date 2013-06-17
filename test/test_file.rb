# ~*~ encoding: utf-8 ~*~
path = File.join(File.dirname(__FILE__), "helper")
require File.expand_path(path)

context "File" do
  setup do
    @wiki = Gollum::Wiki.new(testpath("examples/lotr.git"))
  end

  test "new file" do
    file = Gollum::File.new(@wiki)
    assert_nil file.raw_data
  end

  test "existing file" do
    commit = @wiki.repo.commits.first
    file   = @wiki.file("Mordor/todo.txt")
    assert_equal "[ ] Write section on Ents\n", file.raw_data
    assert_equal 'todo.txt',         file.name
    assert_equal commit.id,          file.version.id
    assert_equal commit.author.name, file.version.author.name
  end

  test "accessing tree" do
    assert_nil @wiki.file("Mordor")
  end
end

context "File with checkout" do
  setup do
    @path = cloned_testpath("examples/lotr.git")
    @wiki = Gollum::Wiki.new(@path)
  end

  teardown do
    FileUtils.rm_rf(@path)
  end

  test "symbolic link" do
    file = @wiki.file("Data-Two.csv")

    assert_match /^FirstName,LastName\n/, file.raw_data
  end

  test "on disk file detection" do
    file = @wiki.file("Bilbo-Baggins.md", 'master', true)
    assert file.on_disk?
  end

  test "on disk file access" do
    file = @wiki.file("Bilbo-Baggins.md", 'master', true)
    path = file.on_disk_path

    assert ::File.exist?(path)
    assert_match /^# Bilbo Baggins\n\nBilbo Baggins/, IO.read(path)
  end

  test "symbolic link, with on-disk" do
    file = @wiki.file("Data-Two.csv", 'master', true)

    assert file.on_disk?
    assert_match /Data\.csv$/, file.on_disk_path
    assert_match /^FirstName,LastName\n/, IO.read(file.on_disk_path)
  end

  test "on disk file, with symlink, raw_data" do
    file = @wiki.file("Data-Two.csv")

    assert_match /^FirstName,LastName\n/, file.raw_data
  end
end
