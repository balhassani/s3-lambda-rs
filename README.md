Prototypes an s3 -> lambda -> kafka workflow.

Components:
  - docker: kafka, localstack, client, server
  - client: writes to s3
  - s3: notifies when bucket changes
  - lambda: sends message to kafka
  - server: receives message from kafka

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

To deploy & invoke the lambda:
```
just deploy
just exec
```