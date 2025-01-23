# Session expiration for Amazon AppStream 2.0
## Overview
A PowerShell script on the instance reads [user metadata](https://docs.aws.amazon.com/appstream2/latest/developerguide/customize-fleets.html#customize-fleets-user-instance-metadata) and passes session information to a Lambda function.
The Lambda function then calls the [DescribeSessions API](https://docs.aws.amazon.com/appstream2/latest/APIReference/API_DescribeSessions.html) and returns the [MaxExpirationTime](https://docs.aws.amazon.com/appstream2/latest/APIReference/API_Session.html#AppStream2-Type-Session-MaxExpirationTime) of the user's session to the PowerShell script, which displays the expiration time and countdown timer.

![Architecture diagram](/images/architecture.png "Architecture")

The date and time are displayed according to the time and locale configured by the user.
For more information, see [Configure Regional Settings](https://docs.aws.amazon.com/appstream2/latest/developerguide/regional-settings-end-user.html).
The window updates once per minute.
When the session has less than 10 minutes remaining, the **Time remaining** text becomes bold and the window remains in the foreground.

![Screenshot of countdown window with 14 remaining](/images/screenshot-streaming-instance-14.png "Screenshot")
![Screenshot of countdown window with nine minutes remaining](/images/screenshot-streaming-instance-9.png "Screenshot")

## Deployment
See [Display session expiration and a countdown timer in Amazon AppStream 2.0](https://aws.amazon.com/blogs/desktop-and-application-streaming/display-session-expiration-and-a-countdown-timer-in-amazon-appstream-2-0/) on the AWS Desktop and Application Streaming blog for deployment instructions.

### CloudFormation template parameters
 **IAM role**

| Parameter | Default  | Description |
| --- | --- | --- |
| **Create fleet IAM role** | `Yes` | Whether or not to create an IAM role (and inline policy) for use by AppStream 2.0 fleets. Possible values: `No` and `Yes`. |

 **Lambda function**

| Parameter | Default  | Description |
| --- | --- | --- |
| **Python logging level** | `INFO` | Possible values: `CRITICAL`, `ERROR`, `WARNING`, `INFO`, and `DEBUG`. |
| **Log retention period** | `7` | Days to retain function logs. Possible values: `1`, `3`, `5`, `7`, `14`, `30`, `60`, `90`, `120`, `150`, `180`, `365`, `400`, `545`, `731`, `1827`, `2192`, `2557`, `2922`, `3288`, and `3653`. |
| **Timeout** | `5` | The amount of time (in seconds) that Lambda allows the function to run before stopping it. Minimum: `1`, maximum: `900`. |
| **Architecture** | `arm64` | See [Lambda instruction set architectures](https://docs.aws.amazon.com/lambda/latest/dg/foundation-arch.html) for more information. |

## Costs
You are responsible for the cost of the AWS services used while running this solution.
The total cost of running this solution depends on the number of streaming sessions.
As of May 2023, the cost for running this solution with default settings in the US East (N. Virginia) Region is approximately $0.01 per month for 10,000 streaming sessions.

## License
This solution is licensed under the MIT-0 License. See the LICENSE file.