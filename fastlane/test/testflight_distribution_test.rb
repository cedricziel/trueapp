require "minitest/autorun"
require_relative "../lib/testflight_distribution"

class TestflightDistributionTest < Minitest::Test
  def test_no_groups_uploads_without_waiting
    assert_equal({ skip_waiting_for_build_processing: true }, TestflightDistribution.upload_options(nil))
  end

  def test_blank_groups_count_as_none
    assert_equal({ skip_waiting_for_build_processing: true }, TestflightDistribution.upload_options(" , "))
  end

  def test_groups_distribute_externally_after_processing
    assert_equal(
      {
        skip_waiting_for_build_processing: false,
        distribute_external: true,
        groups: ["Public Beta"],
        notify_external_testers: true
      },
      TestflightDistribution.upload_options("Public Beta")
    )
  end

  def test_comma_separated_groups_are_split_and_trimmed
    assert_equal ["Public Beta", "Friends"], TestflightDistribution.upload_options("Public Beta, Friends")[:groups]
  end
end
