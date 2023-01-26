Prototypes an s3 -> lambda -> kafka workflow.

*todo!*
  - client: writes to s3
  - s3: notifies when bucket changes
  - lambda: sends message to kafka
  - server: receives message from kafka

To run it all in one go:
```
just do
```

To undo it all in one go:
```
just undo
```

To spin up the services:
```
just start
```

To verify Kafka, run the following in two separate shells:
```
just consume
just produce
```

To provision the env:
```
just provision
```

To build the lambda:

> in prod, run with `--arm64`; for localstack, run [without](https://github.com/localstack/localstack/issues/4921)
```
just build
```

To deploy & invoke the lambda:
```
just deploy
just exec
```