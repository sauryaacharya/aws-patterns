const {S3Client, GetObjectCommand} = require("@aws-sdk/client-s3");

const s3Client = new S3Client();

exports.handler = async (event) => {
    console.log("Event received:", JSON.stringify(event));
    const batchItemFailures = [];

    for (const record of event.Records) {
        const messageId = record.messageId;
        try {
            const messageBody = JSON.parse(record.body);

            for (s3Record of messageBody.Records) {
                const bucket = s3Record.s3.bucket.name;
                const key = s3Record.s3.object.key;

                const response = await s3Client.send(new GetObjectCommand({ Bucket: bucket, Key: key }));
                const fileContent = await response.Body?.transformToString();
                console.log(JSON.parse(fileContent));
            }
        } catch (e) {
            console.error(`Error processing SQS message ${messageId}`, e);
            batchItemFailures.push({ itemIdentifier: messageId });
        }
    }

    return { batchItemFailures };
};
