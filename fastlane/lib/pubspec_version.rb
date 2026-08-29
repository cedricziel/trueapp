# frozen_string_literal: true

# Reads the marketing version from a Flutter pubspec.yaml.
#
#   "version: 1.2.3+45" -> "1.2.3"
#
# release-please owns the x.y.z part; the +build suffix is ignored because CI
# derives the build number from the git commit count at archive time.
module PubspecVersion
  VERSION_LINE = /\Aversion:\s*(\d+\.\d+\.\d+)(?:\+\S+)?\s*\z/

  def self.read(path)
    File.foreach(path) do |line|
      match = VERSION_LINE.match(line)
      return match[1] if match
    end
    raise ArgumentError, "No 'version: x.y.z' line found in #{path}"
  end
end
