use kafka::producer::{Producer, Record, RequiredAcks};
use lambda_runtime::{run, service_fn, Error, LambdaEvent};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::env;
use std::fmt::Write;
use std::time::Duration;
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

    let event_name: &str = &message.records.first()?.event_name;
    let bucket_name: &str = &message.records.first()?.s3.bucket.name;
    let object_key: &str = &message.records.first()?.s3.object.key;

    info!(
        "Deserialized -> event name: {}, bucket name: {}, object key: {}",
        event_name, bucket_name, object_key
    );

    let topic_name = env::var("TOPIC_NAME")?;
    let bootstrap_server = env::var("BOOTSTRAP_SERVER")?;

    let mut producer = Producer::from_hosts(vec![bootstrap_server])
        .with_ack_timeout(Duration::from_secs(1))
        .with_required_acks(RequiredAcks::One)
        .create()?;

    let mut buf = String::with_capacity(object_key.len());
    producer.send(&Record::from_value(topic_name.as_str(), buf.as_bytes()));

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
