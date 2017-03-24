#!/usr/bin/env ruby
# If you get the error "go build runtime: <runtime> must be bootstrapped using make.bash", please run:
# `/bin/bash -ic 'cd $(dirname $(dirname $(which go)))/src && GO386=387 GOARM=5 ./make.bash'`

oses = {
  "darwin" => ["amd64"],
  "dragonfly" => ["amd64"],
  "freebsd" => ["386", "amd64", "arm"],
  "linux" => ["386", "amd64", "arm", "arm64", "ppc64", "ppc64le", "mips", "mipsle"],
  "netbsd" => ["386", "amd64"],
  "openbsd" => ["386", "amd64"],
  "windows" => ["386", "amd64"]}

version = `git describe --abbrev=0 --tags`.chomp
diff = `git diff`.chomp

unless diff.empty?
  puts "Forgot to git reset --hard? (Y/n)"
  exit if gets.chomp != "n"
end

2.times do
  bootstrapped = false
  oses.each do |os, archs|
    next if ARGV.count > 0 && !ARGV.include?(os)
    archs.each do |arch|
      puts "building #{os}-#{arch}"
      name = "syncthing-inotify"
      newname = "syncthing-inotify-#{os}-#{arch}"
      cross = os.gsub(/-v\d/,"")
      if os.include?("windows")
        name = name + ".exe"
      end
      vars = "GOOS=#{os} GOARCH=#{arch}"
      if arch.include?("386")
        vars += " GO386=387"
      end
      if arch.include?("arm")
        vars += " GOARM=5"
      end
      ldflags = "-w -X main.Version=#{version}"
      if os.include?("darwin")
        build = "xgo -go latest --targets=darwin/amd64 -ldflags '#{ldflags}' github.com/syncthing/syncthing-inotify"
        build += " && mv syncthing-inotify-darwin-10.6-amd64 #{name}"
      else
        build = "#{vars} go build -ldflags '#{ldflags}'"
      end
      package = "tar -czf syncthing-inotify-#{os}-#{arch}-#{version}.tar.gz #{name}"
      if os.include?("windows")
        package = "zip syncthing-inotify-#{os}-#{arch}-#{version}.zip #{name}"
      end
      remove = "rm -f #{name}"
      output = `#{build} 2>&1 && #{package} && #{remove}`
      puts output unless output.empty?
      if output.include?("must be bootstrapped") || output.include?("no such tool")
        `cd $(dirname $(which go))/../src && #{vars} ./make.bash --no-clean 1>&2`
        bootstrapped = true
      end
    end
  end
  exit unless bootstrapped
end
