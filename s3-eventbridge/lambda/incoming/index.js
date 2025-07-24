exports.handler = async (event) => {
    console.log("Event received for incoming file:", JSON.stringify(event));
    const bucket = event.detail.bucket.name;
    const key = event.detail.object.key;

    console.log(`Incoming file, Bucket: ${bucket}, Key: ${key}`);
};
