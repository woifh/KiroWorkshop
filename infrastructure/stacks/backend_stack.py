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

        # DynamoDB Tables
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

        users_table = dynamodb.Table(
            self, "UsersTable",
            table_name="Users",
            partition_key=dynamodb.Attribute(
                name="userId",
                type=dynamodb.AttributeType.STRING
            ),
            billing_mode=dynamodb.BillingMode.PAY_PER_REQUEST,
            removal_policy=RemovalPolicy.DESTROY
        )

        registrations_table = dynamodb.Table(
            self, "RegistrationsTable",
            table_name="Registrations",
            partition_key=dynamodb.Attribute(
                name="registrationId",
                type=dynamodb.AttributeType.STRING
            ),
            billing_mode=dynamodb.BillingMode.PAY_PER_REQUEST,
            removal_policy=RemovalPolicy.DESTROY
        )

        # Add GSI for userId-eventId lookup
        registrations_table.add_global_secondary_index(
            index_name="userId-eventId-index",
            partition_key=dynamodb.Attribute(
                name="userId",
                type=dynamodb.AttributeType.STRING
            ),
            sort_key=dynamodb.Attribute(
                name="eventId",
                type=dynamodb.AttributeType.STRING
            ),
            projection_type=dynamodb.ProjectionType.ALL
        )

        # Add GSI for eventId-status lookup
        registrations_table.add_global_secondary_index(
            index_name="eventId-status-index",
            partition_key=dynamodb.Attribute(
                name="eventId",
                type=dynamodb.AttributeType.STRING
            ),
            sort_key=dynamodb.Attribute(
                name="status",
                type=dynamodb.AttributeType.STRING
            ),
            projection_type=dynamodb.ProjectionType.ALL
        )

        # Lambda Function
        import os
        lambda_package_dir = os.path.join(os.path.dirname(__file__), "../lambda_package")
        
        api_lambda = lambda_.Function(
            self, "EventsApiLambda",
            runtime=lambda_.Runtime.PYTHON_3_11,
            handler="main.handler",
            code=lambda_.Code.from_asset(lambda_package_dir),
            memory_size=512,
            timeout=Duration.seconds(30),
            environment={
                "DYNAMODB_TABLE_NAME": events_table.table_name,
                "USERS_TABLE_NAME": users_table.table_name,
                "REGISTRATIONS_TABLE_NAME": registrations_table.table_name
            }
        )

        # Grant Lambda permissions to access DynamoDB
        events_table.grant_read_write_data(api_lambda)
        users_table.grant_read_write_data(api_lambda)
        registrations_table.grant_read_write_data(api_lambda)

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
            self, "EventsTableName",
            value=events_table.table_name,
            description="Events DynamoDB Table Name"
        )

        CfnOutput(
            self, "UsersTableName",
            value=users_table.table_name,
            description="Users DynamoDB Table Name"
        )

        CfnOutput(
            self, "RegistrationsTableName",
            value=registrations_table.table_name,
            description="Registrations DynamoDB Table Name"
        )
