exports.handler = async (event) => {
    console.log("Dynamodb stream:", JSON.stringify(event));

    for (const record of event.Records) {
        console.log(JSON.stringify(record));
    }
}
