require "minitest/autorun"
require "tempfile"
require_relative "../lib/pubspec_version"

class PubspecVersionTest < Minitest::Test
  def with_pubspec(content)
    Tempfile.create(["pubspec", ".yaml"]) do |f|
      f.write(content)
      f.flush
      yield f.path
    end
  end

  def test_strips_build_suffix
    with_pubspec("name: x\nversion: 1.2.3+45\n") { |p| assert_equal "1.2.3", PubspecVersion.read(p) }
  end

  def test_plain_version
    with_pubspec("version: 0.0.1\n") { |p| assert_equal "0.0.1", PubspecVersion.read(p) }
  end

  def test_ignores_indented_version_keys
    with_pubspec("dependencies:\n  foo:\n    version: 9.9.9\nversion: 2.0.0+3\n") { |p| assert_equal "2.0.0", PubspecVersion.read(p) }
  end

  def test_missing_version_raises
    with_pubspec("name: x\n") { |p| assert_raises(ArgumentError) { PubspecVersion.read(p) } }
  end
end
