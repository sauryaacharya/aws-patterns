exports.handler = async (event) => {
    console.log("Event received for alert:", JSON.stringify(event));

    for (const record of event.Records) {
        console.log(record.body)
    }
};
