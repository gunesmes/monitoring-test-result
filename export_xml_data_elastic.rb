#!/usr/bin/env ruby

require 'rexml/document'
require "nokogiri"
require "uri"
require "net/http"
require 'backtrace'


ELASTIC_URL = "http://localhost:9200/app/suite"
PROJECT = ARGV[0]
TEST_RESULT_DIR = "./#{PROJECT}_results"
TEST_TYPE = ARGV[1]

TIME_NOW = Time.now.strftime('%Y-%m-%dT%H:%M:%S')


def export_data()
	# some test produce more than one result file
	Dir.glob("#{TEST_RESULT_DIR}/*.xml") do |xml_file|
		doc = File.open(xml_file) { |f| Nokogiri::XML(f) }
		doc.search("testsuite").each do |test_result| 
			send_data test_result
		end
	end
end

def send_data(line)
	data =  {}	
	
	status = "success"
	if line.attr("failures").to_i > 0
		status = "failed"
	elsif line.attr("errors").to_i > 0
		status = "error"
	end

	timestamp = TIME_NOW

	data.store("testProject", "#{PROJECT}-#{TEST_TYPE}-test")
	data.store("tests", line.attr("tests").to_i)
	data.store("name", line.attr("name"))
	data.store("time", line.attr("time").to_i)
	data.store("errors", line.attr("errors").to_i)
	data.store("failures", line.attr("failures").to_i)
	data.store("timeString", timestamp + "M")
	data.store("analysedAt", timestamp)
	data.store("success", line.attr("tests").to_i - (line.attr("errors").to_i + line.attr("failures").to_i))

	url = URI(ELASTIC_URL)
	http = Net::HTTP.new(url.host, url.port);
	request = Net::HTTP::Post.new(url)
	request["api_key"] = "5513bda43722ed9c10f8d3e35f5a9c4e"
	request["Content-Type"] = "application/json"
	request.body = data.to_s.gsub("=>", ":")

	begin
		response = http.request(request)		
		print("  - new data exported: #{response.code}    data: #{data}\n")
	rescue Net::OpenTimeout => e
		print("Net::OpenTimeout error check the Elasticsearch at #{ELASTIC_URL}\n")
	end

end

if __FILE__ == $0
    export_data()
end
