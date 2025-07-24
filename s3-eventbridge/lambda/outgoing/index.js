exports.handler = async (event) => {
    console.log("Event received for outgoing file:", JSON.stringify(event));

    const bucket = event.detail.bucket.name;
    const key = event.detail.object.key;

    console.log(`Outgoing file, Bucket: ${bucket}, Key: ${key}`);
};
