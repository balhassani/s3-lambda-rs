use kafka::producer::{Producer, Record, RequiredAcks};
use lambda_runtime::{run, service_fn, Error, LambdaEvent};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::env;
use std::time::Duration;
use tracing::{error, info};

#[derive(Serialize)]
struct Response {
    request_id: String,
    message: String,
}

// s3 event message structure:
// https://docs.aws.amazon.com/AmazonS3/latest/userguide/notification-content-structure.html
#[derive(Deserialize)]
struct Message {
    #[serde(rename = "Records")]
    records: Vec<S3Event>,
}

#[derive(Deserialize)]
#[serde(rename = "record")]
struct S3Event {
    #[serde(rename = "eventName")]
    name: String,
    #[serde(rename = "eventSource")]
    source: String,
    #[serde(rename = "eventTime")]
    timestamp: String,
    s3: S3,
}

#[derive(Deserialize)]
struct S3 {
    object: Object,
}

#[derive(Deserialize)]
struct Object {
    key: String,
}

async fn func(event: LambdaEvent<Value>) -> Result<Response, Error> {
    let (value, context) = event.into_parts();
    info!("Received lambda event: {:?}", value);

    let topic = env::var("TOPIC_NAME")?;
    let broker = env::var("BOOTSTRAP_SERVER")?;
    let mut producer = Producer::from_hosts(vec![broker])
        .with_ack_timeout(Duration::from_secs(1))
        .with_required_acks(RequiredAcks::One)
        .create()?;

    let message: Message = serde_json::from_value(value)?;

    for r in &message.records {
        let k = format!("{}-{}-{}", r.source, r.timestamp, r.name);
        let v = &r.s3.object.key;

        match producer.send(&Record::from_key_value(
            topic.as_str(),
            k.as_bytes(),
            v.as_bytes(),
        )) {
            Ok(_) => info!("Sent to topic {topic}: {k} -> {v}"),
            Err(e) => error!("Failed to send: {}", e),
        };
    }

    Ok(Response {
        request_id: context.request_id,
        message: format!("Handled {} s3 event(s).", message.records.len()),
    })
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
