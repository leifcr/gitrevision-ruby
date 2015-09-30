require 'minitest/autorun'
require "#{File.expand_path(File.dirname(__FILE__))}/../gitrevision"
require 'git'
require 'fileutils'
require 'minitest/hooks'
require 'minitest/hooks/test'
class TestGitRevision < MiniTest::Test
  include Minitest::Hooks
  def before_all
    super
    g = Git.init('/tmp/test_git_revision')
    FileUtils.mkdir_p('/tmp/test_git_revision/subfolder')
    FileUtils.mkdir_p('/tmp/test_git_revision_no_repo')
    FileUtils.touch('/tmp/test_git_revision/subfolder/test.txt')
    FileUtils.touch('/tmp/test_git_revision/test.txt')
    g.add('subfolder/test.txt')
    g.add('test.txt')
    g.commit_all('Adding all folders and stuff')
    g.add_tag('v1.2.3',{:a => true, :m => "tv1.2.3"})
  end

  def after_all
    FileUtils.rm_rf('/tmp/test_git_revision_no_repo')
    FileUtils.rm_rf('/tmp/test_git_revision')
    super
  end

  def test_is_git_repo
    g = GitRevision.new('./tests/version.hx', nil, '/tmp/test_git_revision')
    assert g.is_git_repo?(Pathname.new('/tmp/test_git_revision'))
    assert_raises(StandardError) {
      GitRevision.new('./tests/version.hx', nil, '/tmp/test_git_revision_no_repo')
    }
  end

  def test_checks_input_file
    assert_raises(ArgumentError) {
      GitRevision.new('./version.hx', nil, '/tmp/test_git_revision')
    }
  end

  def test_tag_version
    g = GitRevision.new('./tests/version.hx', nil, '/tmp/test_git_revision')
    assert_equal g.tag_version[:major].to_i, 1, "Major should be 1"
    assert_equal g.tag_version[:minor].to_i, 2, "Minor should be 2"
    assert_equal g.tag_version[:revision].to_i, 3, "Revision should be 3"
  end

  def test_find_git_repo_upwards
    g = GitRevision.new('./tests/version.hx', nil, '/tmp/test_git_revision/subfolder')
    assert_equal g.repo_path, '/tmp/test_git_revision'
  end

  def test_output_file
    g = GitRevision.new('./tests/version.hx', nil, '/tmp/test_git_revision')
    assert_equal g.output_file, "#{File.expand_path(File.dirname(__FILE__))}/version.h"
    g = GitRevision.new('./tests/version.hx', './tests/heihei/version2.h', '/tmp/test_git_revision')
    assert_equal g.output_file, "#{File.expand_path(File.dirname(__FILE__))}/heihei/version2.h"
    g = GitRevision.new('./tests/version.hx', '/tmp/version2.h', '/tmp/test_git_revision')
    assert_equal g.output_file, "/tmp/version2.h"
  end

end