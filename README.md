# playing-with-aws

Assumptions and diversions:


Assumption for log format 
1. is JSON 

2. Looks as follows:

{
 "timestamp": "2024-04-03T16:30:00Z",
 "level": "info",
 "message": "User login successful",
 "user_id": "123456",
 "username": "johndoe",
 "ip_address": "192.168.1.100",
 "user_agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4854.51 Safari/537.36",
 "response_time_ms": 50,
 "endpoint": /api/data
}

Assuming that we are storing logs in an s3 bucket or something similar.


Assuming that this alert is the only thing hitting this lambda function with a payload that looks as follows:

{"app_name": "fakepi",
"action": "restart",
"reason": "frequent API timeouts detected"}


No other deviations or assumptions made! Thank you!