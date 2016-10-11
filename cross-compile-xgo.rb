#!/usr/bin/env ruby

targets = "darwin/amd64,
  dragonfly/amd64,
  freebsd/*,
  linux/*,
  netbsd/*,
  openbsd/*,
  windows/*"

targets.gsub!(" ","").gsub!("\n","")

version = `git describe --abbrev=0 --tags`.chomp
diff = `git diff`.chomp

#unless diff.empty?
#  puts "Forgot to git reset --hard?"
#  exit if gets.chomp != "n"
#end

vars = "GO386=387"
ldflags = "-w -X main.Version=#{version}"
build = "#{vars} xgo -v --targets=#{targets} -ldflags '#{ldflags}' ."
puts "Running #{build}"
#`#{build}`

Dir.glob("syncthing-inotify-*").each do |file|
  next unless File.file?(file)
  next if file.include?(".tar.gz")
  name = "syncthing-inotify"
  if file.include?("windows")
    name = "syncthing-inotify.exe"
  end
  move = "cp #{file} #{name}"
  package = "tar -czf #{file}-#{version}.tar.gz #{name}"
  rm = "rm -f syncthing-inotify"
  #rm = "rm -f syncthing-inotify #{name}"
  puts "Packaging #{file}"
  `#{move} && #{package} 
  & #{rm}`
end
