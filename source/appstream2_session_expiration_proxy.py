#!/usr/bin/python
"""
Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
SPDX-License-Identifier: MIT-0

Returns the expiration date and time of an Amazon AppStream 2.0 session.
"""
import logging
import os

import boto3
from botocore.exceptions import ClientError

# Map AppStream_User_Access_Mode session variable values to API values.
AUTH_TYPE_MAPPING: dict[str, str] = {
    "custom": "API",
    "saml": "SAML",
    "userpool": "USERPOOL"
}

logger: logging.Logger = logging.getLogger()
LOG_LEVEL: str = str(os.environ["LOG_LEVEL"])
logger.setLevel(LOG_LEVEL)

as2 = boto3.client("appstream")


def lambda_handler(
    event: dict,
    context: dict # pylint: disable=W0613
) -> dict:
    """
    Lambda event handler.
    """
    try:
        logging.debug(event)
        response = as2.describe_sessions(
            StackName=event["stackName"],
            FleetName=event["resourceName"],
            UserId=event["userName"],
            AuthenticationType=AUTH_TYPE_MAPPING[event["userAccessMode"]]
        )
        if response["Sessions"]:
            for session in response["Sessions"]:
                if session["Id"] == event["sessionId"]:
                    logging.info("Matching session found")
                    return {
                        "statusCode": 200,
                        "maxExpiration": session[
                            "MaxExpirationTime"
                        ].isoformat()
                    }
        logging.info("No matching session found")
        return {
            "statusCode": 404
        }
    except ClientError as ce:
        # Boto3 client error
        logging.error(ce)
        return {
            "statusCode": 500
        }
    except KeyError as ke:
        # Missing or invalid parameter.
        logging.error(ke)
        return {
            "statusCode": 400
        }
