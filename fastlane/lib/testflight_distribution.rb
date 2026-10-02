# frozen_string_literal: true

# Builds the distribution part of the upload_to_testflight parameters from a
# comma-separated list of external group names ("Public Beta, Friends").
#
# External distribution needs the processed build, so naming groups trades the
# fast fire-and-forget upload for waiting on App Store Connect processing,
# after which the build is submitted to Beta App Review for those groups.
module TestflightDistribution
  def self.upload_options(groups)
    names = groups.to_s.split(",").map(&:strip).reject(&:empty?)
    return { skip_waiting_for_build_processing: true } if names.empty?

    {
      skip_waiting_for_build_processing: false,
      distribute_external: true,
      groups: names,
      notify_external_testers: true
    }
  end
end
