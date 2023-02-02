# list available commands
default:
  just -l

# run it all in one go
go: start build provision run

# undo it all in one go
kill: deprovision clean stop nuke

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
  docker exec --interactive --tty broker kafka-console-producer --bootstrap-server broker:9092 --topic s3

# invoke a kafka consumer
consume:
  docker exec --interactive --tty broker kafka-console-consumer --bootstrap-server broker:9092 --topic s3 --from-beginning --property print.key=true --property key.separator=" - "

# set up the env
provision:
  terraform init
  terraform apply -auto-approve

# tear down the env
deprovision:
  terraform destroy -auto-approve

# inspect the env
inspect:
  aws iam list-roles --endpoint-url http://localhost:4566
  aws s3 ls s3://dev --endpoint-url http://localhost:4566 --recursive
  aws lambda list-functions --endpoint-url http://localhost:4566

# build the lambda (note: in prod, run with `--arm64`)
build:
  cargo lambda build --release --output-format zip

# remove the target
clean:
  cargo clean

# deploy the lambda
deploy: build
  aws lambda update-function-code --function-name func --zip-file fileb://./target/lambda/s3-lambda-rs/bootstrap.zip --endpoint-url http://localhost:4566

# invoke the lambda
run: deploy
  aws lambda invoke --function-name func --cli-binary-format raw-in-base64-out --payload "{\"Records\":[{\"eventName\":\"ObjectCreated:Put\",\"s3\":{\"bucket\":{\"name\":\"dev\"},\"object\":{\"key\":\"HappyFace.jpg\"}}}]}" response.json --endpoint-url http://localhost:4566
  cat response.json

# test the lambda
test file:
  aws s3 cp {{file}} s3://dev --endpoint-url http://localhost:4566