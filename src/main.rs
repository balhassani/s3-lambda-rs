use lambda_runtime::{run, service_fn, Error, LambdaEvent};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use tracing::info;

#[derive(Serialize)]
struct Response {
    req_id: String,
    msg: String,
}

// s3 event message structure: 
// https://docs.aws.amazon.com/AmazonS3/latest/userguide/notification-content-structure.html
#[derive(Deserialize)]
struct Message {
    #[serde(rename = "Records")]
    records: Vec<Record>,
}

#[derive(Deserialize)]
#[serde(rename = "record")]
struct Record {
    #[serde(rename = "eventName")]
    event_name: String,
    s3: S3,
}

#[derive(Deserialize)]
struct S3 {
    bucket: Bucket,
    object: Object,
}

#[derive(Deserialize)]
struct Bucket {
    name: String,
}

#[derive(Deserialize)]
struct Object {
    key: String,
}

async fn func(event: LambdaEvent<Value>) -> Result<Response, Error> {
    let (value, context) = event.into_parts();
    info!("Received lambda event -> {:?}", value);

    let message: Message = serde_json::from_value(value)?;

    let event_name = &message.records.first().unwrap().event_name;
    let bucket_name = &message.records.first().unwrap().s3.bucket.name;
    let object_key = &message.records.first().unwrap().s3.object.key;

    info!(
        "Deserialized -> event name: {}, bucket name: {}, object key: {}",
        event_name, bucket_name, object_key
    );

    let resp = Response {
        req_id: context.request_id,
        msg: format!("Received event {} for object {}.", event_name, object_key),
    };

    Ok(resp)
}

#[tokio::main]
async fn main() -> Result<(), Error> {
    tracing_subscriber::fmt()
        .with_max_level(tracing::Level::INFO)
        .with_target(false)
        .without_time()
        .init();

    run(service_fn(func)).await
}
