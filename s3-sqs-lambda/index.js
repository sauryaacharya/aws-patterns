exports.handler = async (event) => {
    console.log("Event received:", JSON.stringify(event));

    for (const record of event.Records) {
        const messageBody = JSON.parse(record.body);

        for (s3Record of messageBody.Records) {
            const bucket = s3Record.s3.bucket.name;
            const key = s3Record.s3.object.key

            console.log(`New file uploaded: Bucket=${bucket}, Key=${key}`);
        }
    }
};
