require "#{File.expand_path(File.dirname(__FILE__))}/gitrevision"
opts = Slop.parse do |o|
  o.string '-i', '--input', 'input filename (relative to current folder) must end with x after the extension if no output is provided '
  o.string '-o', '--output', 'output filename (relative to current folder)'
  o.string '-g', '--gitrepo', 'Git repository'
  o.boolean '-v', '--verbose', "Verbose output"
  o.boolean '-d', '--debug', "Debug output"
  o.on '-h', '--help', 'show help' do
    puts o
    exit
  end
end

unless opts.input?
  puts opts
  puts "\n"
  raise ArgumentError, 'Missing input file'
end

unless opts.output?
  unless opts[:input].end_with?('x')
    puts opts
    puts "\n"
    raise ArgumentError, 'No output file and input file does not end with x'
  end
end

g = GitRevision.new(opts[:input], opts[:output], opts[:gitrepo], opts.verbose?, opts.debug?)
g.create_version_file
