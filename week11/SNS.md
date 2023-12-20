When an application uses polling with SNS, it periodically calls the SNS ReceiveMessage API to retrieve any pending messages from its subscribed SNS topic. [1]

With polling:

Messages are not immediately delivered to the subscriber but are stored in SNS until retrieved. This allows asynchronous processing where the subscriber can retrieve messages at its own pace.
The subscriber is responsible for deleting each message from SNS after processing to prevent duplicate delivery. If a message is not deleted, it will be returned again on subsequent polls.
The ReceiveMessage API allows specifying the maximum number of messages to retrieve in a single call, up to 10 by default. It also returns message attributes and a receipt handle for each message.
After processing messages, the subscriber should call DeleteMessageBatch and provide the receipt handles to confirm processing and remove the messages from the topic.
Polling provides more control over message retrieval but requires the subscriber to periodically call ReceiveMessage to check for new notifications. [2]
Some key considerations for polling intervals include balancing low latency delivery with unnecessary API calls. Subscribers also need to ensure messages are processed and deleted in a timely manner to prevent queue buildup in SNS. Overall, polling provides flexibility for asynchronous processing workflows with SNS.
