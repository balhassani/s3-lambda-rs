# list available commands
default:
  just -l

init: start provision build deploy exec
destroy: clean deprovision stop nuke

# spin up the services
start:
  docker compose up -d

# spin down the services
stop:
  docker compose stop

# remove all containers
nuke:
  docker rm -f $(docker ps -aq)

# remove all images
purge:
  docker system prune --volumes --all --force

# view container logs
tail service="":
  docker compose logs {{service}} --follow

# invoke a kafka producer
produce:
  docker exec --interactive --tty broker kafka-console-producer --bootstrap-server broker:9092 --topic quickstart

# invoke a kafka consumer
consume:
  docker exec --interactive --tty broker kafka-console-consumer --bootstrap-server broker:9092 --topic quickstart --from-beginning

# set up the env
provision:
  terraform init
  terraform apply -auto-approve
  aws iam list-roles --endpoint-url http://localhost:4566
  aws s3 ls s3://dev --endpoint-url http://localhost:4566 --recursive

# tear down the env
deprovision:
  terraform destroy -auto-approve

# build the lambda
build:
  cargo lambda build --release --arm64 --output-format zip

# remove the target
clean:
  cargo clean

# deploy the lambda
deploy:
  aws lambda create-function --function-name func --handler bootstrap --zip-file fileb://./target/lambda/s3-lambda-rs/bootstrap.zip --runtime provided.al2 --role arn:aws:iam::000000000000:role/lambda-exec --environment Variables={RUST_BACKTRACE=1} --tracing-config Mode=Active --endpoint-url http://localhost:4566
  aws lambda list-functions --endpoint-url http://localhost:4566

# invoke the lambda
exec:
  aws lambda invoke --function-name func --invocation-type Event --cli-binary-format raw-in-base64-out --payload "{\"command\": \"hello\"}" response.json --endpoint-url http://localhost:4566
  cat response.json
