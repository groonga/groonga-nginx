# -*- ruby -*-
#
# Copyright(C) 2023  Sutou Kouhei <kou@clear-code.com>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License version 2.1 as published by the Free Software Foundation.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

require_relative "version"

package = "groonga-nginx"
base_name = "#{package}-#{GroongaNginx::VERSION}"
archive_format = "tar.gz"
archive_name = "#{base_name}.#{archive_format}"

dist_files = `git ls-files`.split("\n").reject do |file|
  file.start_with?("packages/")
end

file archive_name => dist_files do
  sh("git",
     "archive",
     "--format=#{archive_format}",
     "--output=#{archive_name}",
     "--prefix=#{base_name}/",
     "HEAD")
end

desc "Create archive"
task :dist => archive_name

desc "Tag #{GroongaNginx::VERSION}"
task :tag do
  changelog = "packages/debian/changelog"
  case File.readlines(changelog)[0]
  when /\((.+)-1\)/
    package_version = $1
    unless package_version == GroongaNginx::VERSION
      raise "package version isn't updated: #{package_version}"
    end
  else
    raise "failed to detect deb package version: #{changelog}"
  end

  sh("git", "tag",
     "-a", GroongaNginx::VERSION,
     "-m", "#{package} #{GroongaNginx::VERSION} has been released!!!")
  sh("git", "push", "--tags")
end
