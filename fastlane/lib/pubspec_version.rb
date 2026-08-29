# frozen_string_literal: true

# Reads the marketing version from a Flutter pubspec.yaml.
#
#   "version: 1.2.3+45" -> "1.2.3"
#
# release-please owns the x.y.z part; the +build suffix is ignored because CI
# derives the build number from the git commit count at archive time.
module PubspecVersion
  VERSION_LINE = /\Aversion:\s*(\d+\.\d+\.\d+)(?:\+\S+)?\s*\z/

  # Anchored here rather than in the Fastfile: fastlane evals the Fastfile,
  # where __dir__ resolves to the repo root, not fastlane/.
  DEFAULT_PATH = File.expand_path("../../pubspec.yaml", __dir__)

  def self.read(path = DEFAULT_PATH)
    File.foreach(path) do |line|
      match = VERSION_LINE.match(line)
      return match[1] if match
    end
    raise ArgumentError, "No 'version: x.y.z' line found in #{path}"
  end
end
