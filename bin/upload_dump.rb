#!/usr/bin/env ruby
require 'rbconfig'
require 'net/http'
require 'cgi'
require 'securerandom'

ROOT = File.expand_path("..", File.dirname(__FILE__))

def dump_syms
  case RbConfig::CONFIG['host_os']
  when /linux/
    dir = 'linux'
  when /darwin/
    dir = 'mac'
  end
  File.join(ROOT, "breakpad", "src", "tools", dir, "dump_syms", "dump_syms")
end

def symbols
  case RbConfig::CONFIG['host_os']
  when /linux/
    file = File.join(ROOT, "bin", "webkit_server")
  when /darwin/
    `dsymutil #{File.join(ROOT, "bin", "webkit_server")}`
    file = File.join(ROOT, "bin", "webkit_server.dSYM")
  end
  `#{dump_syms} #{file}`
end

dump = File.read(ARGV[0])

def file_to_multipart(key,filename,mime_type,content)
  "Content-Disposition: form-data; name=\"#{CGI::escape(key)}\"; filename=\"#{filename}\"\r\n" +
    "Content-Transfer-Encoding: binary\r\n" +
    "Content-Type: #{mime_type}\r\n" +
    "\r\n" +
    "#{content}\r\n"
end

params = [
  file_to_multipart('symbols','webkit_server.sym','application/octet-stream',symbols),
  file_to_multipart('dump','webkit_server.dmp','application/octet-stream',dump) ]

boundary = SecureRandom.hex
query =
  params.collect {|p| '--' + boundary + "\r\n" + p}.join('') + "--" + boundary + "--\r\n"

response = Net::HTTP.start('tranquil-brushlands-9322.herokuapp.com').
  post2("/crash_report",
        query,
        "Content-type" => "multipart/form-data; boundary=" + boundary)
