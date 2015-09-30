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
  def initialize(input_file, output_file, git_repo, verbose)
    @input_file,  @verbose = input_file, verbose
    @git_repo = init_git_repo(git_repo)
    @output_file = real_output_file(output_file)
    self
  end

  def init_git_repo(git_repo)
    if git_repo.nil?
      grepo_path = File.expand_path(Dir.pwd)
    else
      grepo_path = File.expand_path(git_repo)
    end
    f = find_git_repo_upwards(Pathname.new(grepo_path))
    raise StandardError, "No git repository found in path #{grepo_path}, found #{f}"
    Git.open(f)
  end

  def is_git_repo?(pn)
    return true if Dir.exists?(pn.join(".git"))
    false
  end

  def find_git_repo_upwards(pn)
    return pn.to_s if is_git_repo?(pn)
    return nil if pn.root?
    find_git_repo_upwards(pn.split.first)
  end

  def real_output_file(output_file)
    return @input_file.chomp.chop if (output_file.nil?)
    output_file
  end

  #
  # Get tag, short hash and long hash in a hash.
  #
  def git_tag_version
    v = @git_repo.lib.describe('--long').split('-')
    puts v.inspect
    tag_version = v[0].split('.')
    tag_version[0].gsub!('v', '')
    puts tag_version.inspect
    {
      major: tag_version[0],
      minor: tag_version[1],
      revision: tag_version[2],
      short_hash: v[2],
      long_hash: long_hash,
      changes_since_last_tag: v[1]
    }
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
    version = git_tag_version

    # Process line
    File.readlines(@input_file, encoding: 'UTF-8').each do |line|
      output_f.write(process_line(line, version))
    end
    # output to file
    output_f.close
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

opts = Slop.parse do |o|
  o.string '-i', '--input', 'input filename (relative to current folder) must end with x after the extension if no output is provided '
  o.string '-o', '--output', 'output filename (relative to current folder)'
  o.string '-g', '--gitrepo', 'Git repository'
  o.bool '-v', '--verbose', 'enable verbose mode'
  o.on '-h', '--help', 'show help' do
    puts o
    exit
  end
end

puts opts.to_hash.inspect

raise ArgumentError, 'Missing input file' unless opts.input?

unless opts.output?
  raise ArgumentError, 'No output file and input file does not end with x' unless opts[:input].end_with?('x')
end

g = GitRevision.new(opts[:input], opts[:output], opts[:gitrepo], opts.verbose?)
g.create_version_file
