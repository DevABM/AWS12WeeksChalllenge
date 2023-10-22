## Identity Access Management
IAM Role:
AWS Identity and Access Management features manage IAM roles.
 An IAM role is an AWS identity with permission policies that determines what the identity can and cannot do an AWS. It has a many to one relationship. 
 You can enable many users or applications to assume the same role to grant the same set of permissions. 
 A role does not have standard long-term credentials, such as a password, or access keys associated with it. Instead, it provides you with temporary security credentials for your role session. 
 
 The following scenarios highlight some of the challenges that you can address by delegating access, using roles. 
 To grant applications on an Amazon EC2 instance, access to AWS resources, developers might distribute their long-term credentials to each instance. Questions can then use those credentials to access resources, such as Amazon S3 buckets or Amazon DynamoDB data. However, distributing long-term credentials to each instance is challenging to manage and a potential security risk. 
 
 Therefore, the best practice is to use an AWS service role for an EC2 instance. Applications running on that instance can retrieve temporary security credentials and perform actions that the role allows. Use the same process to access, to control or manage access to resources, such as isolating a development environment. 
 From a production environment, you might have multiple AWS accounts. However, in some cases, users from one account might need to access resources in the other account. 
 
 For example, the user from the development environment might require access to the production environment to promote an update. Therefore, users must have credentials for each account, but managing multiple credentials for multiple accounts makes identity management difficult. Using IAM roles, you can take advantage of cross-account access to give users access across AWS accounts when they need it. 
 
 Granting permissions to AWS services. You can use AWS IAM roles to grant permissions for AWS services to call other AWS services on your behalf or create and manage AWS resources for you in your account. AWS services such as Amazon LEX also offer service-linked roles that have predefined permissions, and can be assumed only by that specific service. Thanks for watching. Good.
