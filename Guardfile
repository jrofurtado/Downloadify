# More info at https://github.com/guard/guard#readme
notification :off

# compile when changes are made to as/js files in the src folder
guard :shell do
  watch(%r{(src/(.+/)?[^/]+\.[aj]s)$}) { `sh -c build.sh` }
end

# trigger live reload when static assets are modified
guard 'livereload' do
  watch(%r{(js|media)/.+\.(js|swf)}) { |m| "#{m[2]}" }
  watch(%r{test.html$}) { "html" }
end