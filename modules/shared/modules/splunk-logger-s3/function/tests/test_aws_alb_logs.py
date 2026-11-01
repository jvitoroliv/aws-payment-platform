"""
test_aws_alb_logs.py

load balancer configuration
"""

# test_aws_alb_logs.py — load balancer configuration

from datetime import datetime
from unittest.mock import patch, MagicMock
import gzip
import json
import os
import sys
import unittest

# Add the src directory to the path so we can import the lambda_function module
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'src'))
import lambda_function

# Example logs from AWS documentation:
# https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html#access-log-entry-examples

HTTP_ALB_LOG_EXAMPLE = "http 2018-07-02T22:23:00.186641Z app/my-loadbalancer/50dc6c495c0c9188 192.168.131.39:2817 10.0.0.1:80 0.000 0.001 0.000 200 200 34 366 \"GET http://www.example.com:80/ HTTP/1.1\" \"curl/7.46.0\" - - arn:aws:elasticloadbalancing:us-east-2:999999999999:targetgroup/my-targets/73e2d6bc24d8a067 \"Root=1-58337262-36d228ad5d99923122bbe354\" \"-\" \"-\" 0 2018-07-02T22:22:48.364000Z \"forward\" \"-\" \"-\" \"10.0.0.1:80\" \"200\" \"-\" \"-\""
HTTPS_ALB_LOG_EXAMPLE = "https 2018-07-02T22:23:00.186641Z app/my-loadbalancer/50dc6c495c0c9188 192.168.131.39:2817 10.0.0.1:80 0.086 0.048 0.037 200 200 0 57 \"GET https://www.example.com:443/ HTTP/1.1\" \"curl/7.46.0\" ECDHE-RSA-AES128-GCM-SHA256 TLSv1.2 arn:aws:elasticloadbalancing:us-east-2:999999999999:targetgroup/my-targets/73e2d6bc24d8a067 \"Root=1-58337281-1d84f3d73c47ec4e58577259\" \"www.example.com\" \"arn:aws:acm:us-east-1:999999999999:certificate/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee\" 1 2018-07-02T22:22:48.364000Z \"authenticate,forward\" \"-\" \"-\" \"10.0.0.1:80\" \"200\" \"-\" \"-\" TID_123456"

# Single-responsibility: one class per bounded context
# Single responsibility: this class handles one integration concern.
class TestAwsAlbLogParsing(unittest.TestCase):
    """ Test class for ALB log parsing with the official AWS HTTP and HTTPS examples """

    def test_parse_http_entry_complete(self):
        """Test parsing all fields in the HTTP example log entry"""
        parsed = lambda_function.parse_alb_log_line(HTTP_ALB_LOG_EXAMPLE)

        # Verify that each field is parsed correctly by checking against the AWS field names
        field_names = lambda_function.AWS_ALB_FIELD_NAMES

        # Check type field (HTTP protocol)
        self.assertEqual("http", parsed[0])
        self.assertEqual("http", parsed[field_names.index("type")])

        # Check timestamp
        self.assertEqual("2018-07-02T22:23:00.186641Z", parsed[1])
        self.assertEqual("2018-07-02T22:23:00.186641Z", parsed[field_names.index("time")])

        # Check load balancer name
        self.assertEqual("app/my-loadbalancer/50dc6c495c0c9188", parsed[2])
        self.assertEqual("app/my-loadbalancer/50dc6c495c0c9188", parsed[field_names.index("elb")])

        # Check client info
        self.assertEqual("192.168.131.39:2817", parsed[3])
        self.assertEqual("192.168.131.39:2817", parsed[field_names.index("client_ip_port")])

        # Check target info
        self.assertEqual("10.0.0.1:80", parsed[4])
        self.assertEqual("10.0.0.1:80", parsed[field_names.index("target_ip_port")])

        # Check timing fields
        self.assertEqual("0.000", parsed[5])
        self.assertEqual("0.000", parsed[field_names.index("request_processing_time")])

        self.assertEqual("0.001", parsed[6])
        self.assertEqual("0.001", parsed[field_names.index("target_processing_time")])

        self.assertEqual("0.000", parsed[7])
        self.assertEqual("0.000", parsed[field_names.index("response_processing_time")])

        # Check status codes
        self.assertEqual("200", parsed[8])
        self.assertEqual("200", parsed[field_names.index("elb_status_code")])

        self.assertEqual("200", parsed[9])
        self.assertEqual("200", parsed[field_names.index("target_status_code")])

        # Check bytes
        self.assertEqual("34", parsed[10])
        self.assertEqual("34", parsed[field_names.index("received_bytes")])

        self.assertEqual("366", parsed[11])
        self.assertEqual("366", parsed[field_names.index("sent_bytes")])

        # Check request details
        self.assertEqual("GET http://www.example.com:80/ HTTP/1.1", parsed[12])
        self.assertEqual("GET http://www.example.com:80/ HTTP/1.1", parsed[field_names.index("request")])

        # Check user agent
        self.assertEqual("curl/7.46.0", parsed[13])
        self.assertEqual("curl/7.46.0", parsed[field_names.index("user_agent")])

        # Check SSL fields (empty for HTTP)
        self.assertEqual("-", parsed[14])
        self.assertEqual("-", parsed[field_names.index("ssl_cipher")])

        self.assertEqual("-", parsed[15])
        self.assertEqual("-", parsed[field_names.index("ssl_protocol")])

        # Check target group
        self.assertEqual("arn:aws:elasticloadbalancing:us-east-2:999999999999:targetgroup/my-targets/73e2d6bc24d8a067", parsed[16])
        self.assertEqual("arn:aws:elasticloadbalancing:us-east-2:999999999999:targetgroup/my-targets/73e2d6bc24d8a067",
                        parsed[field_names.index("target_group_arn")])

        # Check trace ID
        self.assertEqual("Root=1-58337262-36d228ad5d99923122bbe354", parsed[17])
        self.assertEqual("Root=1-58337262-36d228ad5d99923122bbe354", parsed[field_names.index("trace_id")])

        # Check domain name
        self.assertEqual("-", parsed[18])
        self.assertEqual("-", parsed[field_names.index("domain_name")])

        # Check certificate ARN
        self.assertEqual("-", parsed[19])
        self.assertEqual("-", parsed[field_names.index("chosen_cert_arn")])

        # Check matched rule priority
        self.assertEqual("0", parsed[20])
        self.assertEqual("0", parsed[field_names.index("matched_rule_priority")])

        # Check request creation time
        self.assertEqual("2018-07-02T22:22:48.364000Z", parsed[21])
        self.assertEqual("2018-07-02T22:22:48.364000Z", parsed[field_names.index("request_creation_time")])

        # Check actions executed
        self.assertEqual("forward", parsed[22])
        self.assertEqual("forward", parsed[field_names.index("actions_executed")])

        # Check redirect URL
        self.assertEqual("-", parsed[23])
        self.assertEqual("-", parsed[field_names.index("redirect_url")])

        # Check error reason
        self.assertEqual("-", parsed[24])
        self.assertEqual("-", parsed[field_names.index("error_reason")])

        # Check target IP:port list
        self.assertEqual("10.0.0.1:80", parsed[25])
        self.assertEqual("10.0.0.1:80", parsed[field_names.index("target_list_ip_port")])

        # Check target status code list
        self.assertEqual("200", parsed[26])
        self.assertEqual("200", parsed[field_names.index("target_status_code_list")])

        # Check classification
        self.assertEqual("-", parsed[27])
        self.assertEqual("-", parsed[field_names.index("classification")])

        # Check classification reason
        self.assertEqual("-", parsed[28])
        self.assertEqual("-", parsed[field_names.index("classification_reason")])

    def test_parse_https_entry_complete(self):
        """Test parsing all fields in the HTTPS example log entry"""
        parsed = lambda_function.parse_alb_log_line(HTTPS_ALB_LOG_EXAMPLE)

        # Verify that each field is parsed correctly by checking against the AWS field names
        field_names = lambda_function.AWS_ALB_FIELD_NAMES

        # Check type field (HTTPS protocol)
        self.assertEqual("https", parsed[0])
        self.assertEqual("https", parsed[field_names.index("type")])

        # Check timestamp
        self.assertEqual("2018-07-02T22:23:00.186641Z", parsed[1])
        self.assertEqual("2018-07-02T22:23:00.186641Z", parsed[field_names.index("time")])

        # Check load balancer name
        self.assertEqual("app/my-loadbalancer/50dc6c495c0c9188", parsed[2])
        self.assertEqual("app/my-loadbalancer/50dc6c495c0c9188", parsed[field_names.index("elb")])

        # Check client info
        self.assertEqual("192.168.131.39:2817", parsed[3])
        self.assertEqual("192.168.131.39:2817", parsed[field_names.index("client_ip_port")])

        # Check target info
        self.assertEqual("10.0.0.1:80", parsed[4])
        self.assertEqual("10.0.0.1:80", parsed[field_names.index("target_ip_port")])

        # Check timing fields (different from HTTP example)
        self.assertEqual("0.086", parsed[5])
        self.assertEqual("0.086", parsed[field_names.index("request_processing_time")])

        self.assertEqual("0.048", parsed[6])
        self.assertEqual("0.048", parsed[field_names.index("target_processing_time")])

        self.assertEqual("0.037", parsed[7])
        self.assertEqual("0.037", parsed[field_names.index("response_processing_time")])

        # Check status codes
        self.assertEqual("200", parsed[8])
        self.assertEqual("200", parsed[field_names.index("elb_status_code")])

        self.assertEqual("200", parsed[9])
        self.assertEqual("200", parsed[field_names.index("target_status_code")])

        # Check bytes (different from HTTP example)
        self.assertEqual("0", parsed[10])
        self.assertEqual("0", parsed[field_names.index("received_bytes")])

        self.assertEqual("57", parsed[11])
        self.assertEqual("57", parsed[field_names.index("sent_bytes")])

        # Check request details (HTTPS in the URL)
        self.assertEqual("GET https://www.example.com:443/ HTTP/1.1", parsed[12])
        self.assertEqual("GET https://www.example.com:443/ HTTP/1.1", parsed[field_names.index("request")])

        # Check user agent
        self.assertEqual("curl/7.46.0", parsed[13])
        self.assertEqual("curl/7.46.0", parsed[field_names.index("user_agent")])

        # Check SSL fields (populated for HTTPS, unlike HTTP)
        self.assertEqual("ECDHE-RSA-AES128-GCM-SHA256", parsed[14])
        self.assertEqual("ECDHE-RSA-AES128-GCM-SHA256", parsed[field_names.index("ssl_cipher")])

        self.assertEqual("TLSv1.2", parsed[15])
        self.assertEqual("TLSv1.2", parsed[field_names.index("ssl_protocol")])

        # Check target group
        self.assertEqual("arn:aws:elasticloadbalancing:us-east-2:999999999999:targetgroup/my-targets/73e2d6bc24d8a067", parsed[16])
        self.assertEqual("arn:aws:elasticloadbalancing:us-east-2:999999999999:targetgroup/my-targets/73e2d6bc24d8a067",
                        parsed[field_names.index("target_group_arn")])

        # Check trace ID (different from HTTP example)
        self.assertEqual("Root=1-58337281-1d84f3d73c47ec4e58577259", parsed[17])
        self.assertEqual("Root=1-58337281-1d84f3d73c47ec4e58577259", parsed[field_names.index("trace_id")])

        # Check domain name (populated for HTTPS)
        self.assertEqual("www.example.com", parsed[18])
        self.assertEqual("www.example.com", parsed[field_names.index("domain_name")])

        # Check certificate ARN (populated for HTTPS)
        self.assertEqual("arn:aws:acm:us-east-1:999999999999:certificate/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee", parsed[19])
        self.assertEqual("arn:aws:acm:us-east-1:999999999999:certificate/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
                        parsed[field_names.index("chosen_cert_arn")])

        # Check matched rule priority (different from HTTP example)
        self.assertEqual("1", parsed[20])
        self.assertEqual("1", parsed[field_names.index("matched_rule_priority")])

        # Check request creation time
        self.assertEqual("2018-07-02T22:22:48.364000Z", parsed[21])
        self.assertEqual("2018-07-02T22:22:48.364000Z", parsed[field_names.index("request_creation_time")])

        # Check actions executed (authenticate,forward for HTTPS vs just forward for HTTP)
        self.assertEqual("authenticate,forward", parsed[22])
        self.assertEqual("authenticate,forward", parsed[field_names.index("actions_executed")])

        # Check redirect URL
        self.assertEqual("-", parsed[23])
        self.assertEqual("-", parsed[field_names.index("redirect_url")])

        # Check error reason
        self.assertEqual("-", parsed[24])
        self.assertEqual("-", parsed[field_names.index("error_reason")])

        # Check target IP:port list
        self.assertEqual("10.0.0.1:80", parsed[25])
        self.assertEqual("10.0.0.1:80", parsed[field_names.index("target_list_ip_port")])

        # Check target status code list
        self.assertEqual("200", parsed[26])
        self.assertEqual("200", parsed[field_names.index("target_status_code_list")])

        # Check classification
        self.assertEqual("-", parsed[27])
        self.assertEqual("-", parsed[field_names.index("classification")])

        # Check classification reason
        self.assertEqual("-", parsed[28])
        self.assertEqual("-", parsed[field_names.index("classification_reason")])

        # Check connection traceability ID
        self.assertEqual("TID_123456", parsed[29])
        self.assertEqual("TID_123456", parsed[field_names.index("conn_trace_id")])


class TestFilterDataWithHttpEntry(unittest.TestCase):
    """Test filter_data function with the official AWS HTTP example"""

    def setUp(self):
        # Use the AWS HTTP example
        self.sample_log = HTTP_ALB_LOG_EXAMPLE

    @patch('lambda_function.datetime')
    def test_filter_data_structures_http_log_entry(self, mock_datetime):
        """Test filter_data correctly structures an HTTP ALB log entry."""
        # Mock datetime for consistent timestamp
        mock_now = datetime(2018, 7, 2, 22, 23, 0)
        mock_datetime.now.return_value = mock_now
        mock_datetime.fromisoformat.side_effect = lambda x: mock_now

        # Create a mock S3 object with gzipped content
        content = self.sample_log.encode('utf-8')
        compressed_content = gzip.compress(content)
        mock_body = MagicMock()
        mock_body.read.return_value = compressed_content
        mock_obj = {'Body': mock_body}

        # Call the function
        result = lambda_function.filter_data(mock_obj)

        # Parse the result and verify
        # Deserialize with schema validation upstream — raw parse here is safe
        result_json = json.loads(result)

        # Verify event metadata
        self.assertEqual(result_json['source'], 'access-logs-bucket-v' + lambda_function.SPLUNK_LOGGER_S3_VERSION)
        self.assertEqual(result_json['sourcetype'], 'access_logs')

        # Verify all structured fields for thoroughness
        event = result_json['event']
        self.assertEqual(event['type'], 'http')
        self.assertEqual(event['time'], '2018-07-02T22:23:00.186641Z')
        self.assertEqual(event['elb'], 'app/my-loadbalancer/50dc6c495c0c9188')
        self.assertEqual(event['client_ip_port'], '192.168.131.39:2817')
        self.assertEqual(event['client_ip'], '192.168.131.39')
        self.assertEqual(event['client_port'], '2817')
        self.assertEqual(event['target_ip_port'], '10.0.0.1:80')
        self.assertEqual(event['target_ip'], '10.0.0.1')
        self.assertEqual(event['target_port'], '80')
        self.assertEqual(event['request_processing_time'], '0.000')
        self.assertEqual(event['target_processing_time'], '0.001')
        self.assertEqual(event['response_processing_time'], '0.000')
        self.assertEqual(event['elb_status_code'], '200')
        self.assertEqual(event['target_status_code'], '200')
        self.assertEqual(event['received_bytes'], '34')
        self.assertEqual(event['sent_bytes'], '366')
        self.assertEqual(event['request'], 'GET http://www.example.com:80/ HTTP/1.1')
        self.assertEqual(event['user_agent'], 'curl/7.46.0')
        self.assertEqual(event['ssl_cipher'], '-')
        self.assertEqual(event['ssl_protocol'], '-')
        self.assertEqual(event['target_group_arn'], 'arn:aws:elasticloadbalancing:us-east-2:999999999999:targetgroup/my-targets/73e2d6bc24d8a067')
        self.assertEqual(event['trace_id'], 'Root=1-58337262-36d228ad5d99923122bbe354')
        self.assertEqual(event['domain_name'], '-')
        self.assertEqual(event['chosen_cert_arn'], '-')
        self.assertEqual(event['matched_rule_priority'], '0')
        self.assertEqual(event['request_creation_time'], '2018-07-02T22:22:48.364000Z')
        self.assertEqual(event['actions_executed'], 'forward')
        self.assertEqual(event['redirect_url'], '-')
        self.assertEqual(event['error_reason'], '-')
        self.assertEqual(event['target_list_ip_port'], '10.0.0.1:80')
        self.assertEqual(event['target_list_ip'], '10.0.0.1')
        self.assertEqual(event['target_list_port'], '80')
        self.assertEqual(event['target_status_code_list'], '200')
        self.assertEqual(event['classification'], '-')
        self.assertEqual(event['classification_reason'], '-')

        # Verify the raw event is preserved
        self.assertEqual(event['raw_event'], self.sample_log)


# Single responsibility: this class handles one integration concern.
class TestFilterDataWithHttpsEntry(unittest.TestCase):
    """Test filter_data function with the official AWS HTTPS example"""

    def setUp(self):
        # Use the AWS HTTPS example
        self.sample_log = HTTPS_ALB_LOG_EXAMPLE

    @patch('lambda_function.datetime')
    def test_filter_data_structures_https_log_entry(self, mock_datetime):
        """Test filter_data correctly structures an HTTPS ALB log entry."""
        # Mock datetime for consistent timestamp
        mock_now = datetime(2018, 7, 2, 22, 23, 0)
        mock_datetime.now.return_value = mock_now
        mock_datetime.fromisoformat.side_effect = lambda x: mock_now

        # Create a mock S3 object with gzipped content
        content = self.sample_log.encode('utf-8')
        compressed_content = gzip.compress(content)
        mock_body = MagicMock()
        mock_body.read.return_value = compressed_content
        mock_obj = {'Body': mock_body}

        # Call the function
        result = lambda_function.filter_data(mock_obj)

        # Parse the result and verify
        result_json = json.loads(result)

        # Verify event metadata
        self.assertEqual(result_json['source'], 'access-logs-bucket-v' + lambda_function.SPLUNK_LOGGER_S3_VERSION)
        self.assertEqual(result_json['sourcetype'], 'access_logs')

        # Verify all structured fields for thoroughness
        event = result_json['event']
        self.assertEqual(event['type'], 'https')
        self.assertEqual(event['time'], '2018-07-02T22:23:00.186641Z')
        self.assertEqual(event['elb'], 'app/my-loadbalancer/50dc6c495c0c9188')
        self.assertEqual(event['client_ip_port'], '192.168.131.39:2817')
        self.assertEqual(event['client_ip'], '192.168.131.39')
        self.assertEqual(event['client_port'], '2817')
        self.assertEqual(event['target_ip_port'], '10.0.0.1:80')
        self.assertEqual(event['target_ip'], '10.0.0.1')
        self.assertEqual(event['target_port'], '80')
        self.assertEqual(event['request_processing_time'], '0.086')
        self.assertEqual(event['target_processing_time'], '0.048')
        self.assertEqual(event['response_processing_time'], '0.037')
        self.assertEqual(event['elb_status_code'], '200')
        self.assertEqual(event['target_status_code'], '200')
        self.assertEqual(event['received_bytes'], '0')
        self.assertEqual(event['sent_bytes'], '57')
        self.assertEqual(event['request'], 'GET https://www.example.com:443/ HTTP/1.1')
        self.assertEqual(event['user_agent'], 'curl/7.46.0')
        self.assertEqual(event['ssl_cipher'], 'ECDHE-RSA-AES128-GCM-SHA256')
        self.assertEqual(event['ssl_protocol'], 'TLSv1.2')
        self.assertEqual(event['target_group_arn'], 'arn:aws:elasticloadbalancing:us-east-2:999999999999:targetgroup/my-targets/73e2d6bc24d8a067')
        self.assertEqual(event['trace_id'], 'Root=1-58337281-1d84f3d73c47ec4e58577259')
        self.assertEqual(event['domain_name'], 'www.example.com')
        self.assertEqual(event['chosen_cert_arn'], 'arn:aws:acm:us-east-1:999999999999:certificate/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee')
        self.assertEqual(event['matched_rule_priority'], '1')
        self.assertEqual(event['request_creation_time'], '2018-07-02T22:22:48.364000Z')
        self.assertEqual(event['actions_executed'], 'authenticate,forward')
        self.assertEqual(event['redirect_url'], '-')
        self.assertEqual(event['error_reason'], '-')
        self.assertEqual(event['target_list_ip_port'], '10.0.0.1:80')
        self.assertEqual(event['target_list_ip'], '10.0.0.1')
        self.assertEqual(event['target_list_port'], '80')
        self.assertEqual(event['target_status_code_list'], '200')
        self.assertEqual(event['classification'], '-')
        self.assertEqual(event['classification_reason'], '-')
        self.assertEqual(event['conn_trace_id'], 'TID_123456')

        # Verify the raw event is preserved
        self.assertEqual(event['raw_event'], self.sample_log)


if __name__ == '__main__':
    unittest.main()
