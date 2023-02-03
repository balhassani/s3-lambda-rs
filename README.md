# Prototypes an s3 -> lambda -> kafka workflow

## Workflow
  - client writes to s3
  - s3 notifies when bucket changes
  - on change, lambda sends message to kafka
  - server receives message from kafka

## Dev notes

> Requires [cargo-lambda](https://github.com/cargo-lambda/cargo-lambda)

> Currently only compiles under WSL!

## Basic commands

To set up:
```
just go
```

To iterate:
```
just run
```

To test the lambda:
```
just consume
just test <file>
```

To tear down:
```
just kill
```

## Specific commands

To spin up the services:
```
just start
```

To verify Kafka, run the following in two separate shells:
```
just consume
just produce
```

To provision the env (s3, iam, lambda):
```
just provision
```

To build the lambda:

> in prod, run with `--arm64`; for localstack, run [without](https://github.com/localstack/localstack/issues/4921)
```
just build
```
