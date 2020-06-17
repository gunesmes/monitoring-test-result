from xml.etree import ElementTree as ET
import requests
import time
import datetime
import sys
import json
import glob

args = sys.argv[1:]

ELASTIC_URL = "http://localhost:9200/app/suite"
PROJECT = args[0]
TIME_NOW = datetime.datetime.fromtimestamp(time.time()).strftime('%Y-%m-%dT%H:%M:%S')
TEST_RESULT_DIR = "./%s_results/*" %PROJECT


def export_data():
	# some test produce more than one result file
	xml_files = glob.glob(TEST_RESULT_DIR)

	for xml_file in xml_files:
		tree = ET.parse(xml_file)
		root = tree.getroot()
		testsuites = root.findall("testsuite")

		if len(testsuites) == 0:
			send_data(root)
		else:
			for line in testsuites:
				send_data(line)


def send_data(line):
	data =  line.attrib
	headers = {
    'Content-Type': "application/json",
    'cache-control': "no-cache"
  }
	
	status = "success"
	if int(data["failures"]) > 0:
		status = "failed"
	elif int(data["errors"]) > 0:
		status = "error"

	# try:
	# 	timestamp = data["timestamp"]
	# except:
	# 	# there may be no timestamp
	timestamp = TIME_NOW


	data["testProject"] = PROJECT + "-ui-test"
	data["tests"] = int(data["tests"])
	data["errors"] = int(data["errors"])
	data["failures"] = int(data["failures"])
	data["timeString"] = timestamp + "M"
	data["timestamp"] = timestamp
	data["success"] = int(data["tests"]) - (int(data["errors"]) + int(data["failures"]))

	response = requests.post(ELASTIC_URL, json=data, headers=headers)

	print("  - new data exported: %s\n    data: %s" %(str(response.status_code), data))


if __name__ == "__main__":
   export_data()
