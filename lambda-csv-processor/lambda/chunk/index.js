import { S3Client, GetObjectCommand } from "@aws-sdk/client-s3";
import { SQSClient, SendMessageBatchCommand } from "@aws-sdk/client-sqs";
import * as csv from 'fast-csv';
import pLimit from "p-limit";
import { randomUUID } from 'crypto';

const QUEUE_URL = process.env.QUEUE_URL;
const BATCH_SIZE = 10;
const s3Client = new S3Client({});
const sqsClient = new SQSClient({});
const limit = pLimit(20);

export const handler = async (event) => {
    const record = event.Records[0];
    const bucket = record.s3.bucket.name;
    const key = decodeURIComponent(record.s3.object.key.replace(/\+/g, ' '));
    const s3Stream = await getObjectStream(bucket, key);
    await processCsvStream(s3Stream);
    console.log('All batches sent to SQS');
};

async function getObjectStream(bucket, key) {
    const s3Response = await s3Client.send(
        new GetObjectCommand({ Bucket: bucket, Key: key })
    );

    return s3Response.Body;
}

async function sendSQSBatchMessage(messages) {
    const entries = messages.map((item, index) => ({
        Id: randomUUID(),
        MessageBody: JSON.stringify(item),
    }));

    return sqsClient.send(
        new SendMessageBatchCommand({
            QueueUrl: QUEUE_URL,
            Entries: entries,
        })
    );
}

async function processCsvStream(csvStream) {
    return new Promise((resolve, reject) => {
        const allPromises = [];
        let batch = [];
        let totalRows = 0;
        let totalBatches = 0;
        csv.parseStream(csvStream, { headers: true })
            .on('data', (row) => {
                totalRows++;
                batch.push(row);
                if (batch.length === BATCH_SIZE) {
                    totalBatches++;
                    const currentBatch = [...batch];
                    batch = [];
                    allPromises.push(limit(() => sendSQSBatchMessage(currentBatch)));
                }
            })
            .on('end', async () => {
                if (batch.length > 0) {
                    totalBatches++;
                    allPromises.push(limit(() => sendSQSBatchMessage(batch)));
                }
                await Promise.all(allPromises);
                console.log(`Total rows processed: ${totalRows}`);
                console.log(`Total batches sent: ${totalBatches}`);
                resolve();
            })
            .on('error', (err) => {
                limit.clearQueue();
                reject(err);
            });
    });
}
