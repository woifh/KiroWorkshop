from aws_cdk import (
    Stack,
    aws_dynamodb as dynamodb,
    aws_lambda as lambda_,
    aws_apigateway as apigateway,
    RemovalPolicy,
    CfnOutput,
    Duration
)
from constructs import Construct


class BackendStack(Stack):
    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        # DynamoDB Table
        events_table = dynamodb.Table(
            self, "EventsTable",
            table_name="Events",
            partition_key=dynamodb.Attribute(
                name="eventId",
                type=dynamodb.AttributeType.STRING
            ),
            billing_mode=dynamodb.BillingMode.PAY_PER_REQUEST,
            removal_policy=RemovalPolicy.DESTROY
        )

        # Lambda Function
        api_lambda = lambda_.DockerImageFunction(
            self, "EventsApiLambda",
            code=lambda_.DockerImageCode.from_image_asset(
                directory="../backend",
                file="Dockerfile"
            ),
            memory_size=512,
            timeout=Duration.seconds(30),
            environment={
                "DYNAMODB_TABLE_NAME": events_table.table_name
            }
        )

        # Grant Lambda permissions to access DynamoDB
        events_table.grant_read_write_data(api_lambda)

        # API Gateway
        api = apigateway.LambdaRestApi(
            self, "EventsApi",
            handler=api_lambda,
            proxy=True,
            default_cors_preflight_options=apigateway.CorsOptions(
                allow_origins=apigateway.Cors.ALL_ORIGINS,
                allow_methods=apigateway.Cors.ALL_METHODS,
                allow_headers=["*"]
            )
        )

        # Outputs
        CfnOutput(
            self, "ApiUrl",
            value=api.url,
            description="Events API URL"
        )
        
        CfnOutput(
            self, "TableName",
            value=events_table.table_name,
            description="DynamoDB Table Name"
        )
