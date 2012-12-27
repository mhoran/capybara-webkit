#!/usr/bin/env ruby
require 'net/http'
require 'cgi'

root = File.expand_path("..", File.dirname(__FILE__))
dump_syms = File.join(root, "breakpad", "src", "tools", "linux", "dump_syms", "dump_syms")
data = `#{dump_syms} #{File.join(root, "bin", "webkit_server")}`

def file_to_multipart(key,filename,mime_type,content)
  "Content-Disposition: form-data; name=\"#{CGI::escape(key)}\"; filename=\"#{filename}\"\r\n" +
    "Content-Transfer-Encoding: binary\r\n" +
    "Content-Type: #{mime_type}\r\n" +
    "\r\n" +
    "#{content}\r\n"
end

params = [
  file_to_multipart('symbols','webkit_server.sym','application/octet-stream',data),
  file_to_multipart('dump','webkit_server.dmp','application/octet-stream',File.read(ARGV[0])) ]

boundary = '349832898984244898448024464570528145'
query =
  params.collect {|p| '--' + boundary + "\r\n" + p}.join('') + "--" + boundary + "--\r\n"

response = Net::HTTP.start('tranquil-brushlands-9322.herokuapp.com').
  post2("/crash_report",
        query,
        "Content-type" => "multipart/form-data; boundary=" + boundary)
