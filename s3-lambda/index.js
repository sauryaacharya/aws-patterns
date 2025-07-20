exports.handler = async (event) => {
    console.log("S3 Event:", JSON.stringify(event));

    for (const record of event.Records) {
        const bucket = record.s3.bucket.name;
        const key = record.s3.object.key;
        console.log(`File uploaded: s3://${bucket}/${key}`);
    }
}
