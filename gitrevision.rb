#
# Git revision ruby can set git information in source files.
#
# @author Leif Ringstad <leif@bitelm.com>
#
require 'git'
require 'slop'
require 'pathname'

class GitRevision
  # Note:
  # Format of tags must be either v1.0.1 or 1.0.1 for major: 1, minor: 0, revision: 1
  # (Semantic versioning)
  #
  def initialize(input_file, output_file, git_repo, verbose = false, debug = false)
    @verbose, @debug = verbose, debug
    puts "GitRevision: initialize Input: #{input_file} Output: #{output_file} Repo: #{git_repo}" if @verbose
    @input_file = input_file_with_path(input_file)
    @git_repo = open_git_repo(git_repo)
    @output_file = real_output_file(output_file)
    self
  end

  def input_file_with_path(input_file)
    if !File.exist?(input_file)
      raise ArgumentError, "Input file #{File.expand_path(input_file)} is not found"
    end
    File.expand_path(input_file)
  end

  def open_git_repo(git_repo)
    puts "GitRevision: open_git_repo #{git_repo}" if @debug
    if git_repo.nil?
      grepo_path = File.expand_path(Dir.pwd)
    else
      grepo_path = File.expand_path(git_repo)
    end
    @repo_path = find_git_repo_upwards(Pathname.new(grepo_path))
    raise StandardError, "No git repository found in path #{grepo_path}" if @repo_path.nil?
    Git.open(@repo_path)
  end

  def repo_path
    @repo_path
  end

  def is_git_repo?(pn)
    puts "GitRevision: is_git_repo #{pn.to_s}" if @debug
    return true if Dir.exist?(pn.join(".git"))
    false
  end

  def find_git_repo_upwards(pn)
    puts "GitRevision: find_git_repo_upwards #{pn.to_s}" if @debug
    return pn.to_s if is_git_repo?(pn)
    return nil if pn.root?
    find_git_repo_upwards(pn.split.first)
  end

  def real_output_file(output_file)
    return @input_file.chomp.chop if (output_file.nil?)
    File.expand_path(output_file)
  end

  def output_file
    @output_file
  end

  #
  # Get tag, short hash and long hash in a hash.
  #
  def tag_version
    v = @git_repo.lib.describe('--long').split('-')
    tag_version = v[0].split('.')
    tag_version[0].gsub!('v', '')
    r = {
      major: tag_version[0],
      minor: tag_version[1],
      revision: tag_version[2],
      short_hash: v[2],
      long_hash: long_hash,
      changes_since_last_tag: v[1]
    }
    puts "GitRevision: tag_version #{r.inspect}" if @debug
    r
  end

  #
  # Get long hash
  #
  def long_hash
    @git_repo.revparse('HEAD')
  end

  #
  # Create the version file
  #
  def create_version_file
    output_f = File.new(@output_file, 'w:UTF-8')
    # Read each line from the file
    version = tag_version

    # Process line
    File.readlines(@input_file, encoding: 'UTF-8').each do |line|
      output_f.write(process_line(line, version))
    end
    # output to file
    output_f.close
    puts "GitRevision: Created file #{@output_file} from #{@input_file}."
    puts "GitRevision: version: #{version[:major]}.#{version[:minor]}.#{version[:revision]} short_hash: #{version[:short_hash]} long_hash: #{version[:long_hash]}"
    output_f = nil
  end

  #
  # Process lines
  #
  def process_line(line, version)
    line.gsub!('$GIT_MAJOR_VERSION$', version[:major])
    line.gsub!('$GIT_MINOR_VERSION$', version[:minor])
    line.gsub!('$GIT_REVISION$', version[:revision])
    line.gsub!('$GIT_SHORT_HASH$', version[:short_hash])
    line.gsub!('$GIT_LONG_HASH$', version[:long_hash])
    line.gsub!('$GIT_COMMITS_SINCE_TAG$', version[:changes_since_last_tag])
    line
  end
end

# Add describe function (needed for version data)
module Git
  class Lib
    def describe(opts = [], chdir = true, redirect = '', &block)
      command('describe', opts, chdir, redirect, &block)
    end
  end
end
