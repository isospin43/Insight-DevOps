# Insight-DevOps

Project Idea: Unified monitoring across multiple cloud platforms for cost optimization and risk mitigation.

What is the purpose, and most common use cases?

- First looking at basic operational costs through a monitoring application. This will direct the management system to properly utilize services/resources across the different clouds. This will be done in the simplest use case by using pricing history for different services for each of the platforms.

- Once cost and perhaps other metrics are incorperated, a customer application can be used in conjuction with the the monitoring application ( not accessible to the customer ) to optimize the operational cost of running the application. This may lead to pricing benefits both for the application provider and the customer using the application.

- Cost optimization aspect: This would require as mentioned before, batch processing from some pricing history database on a very small subset of services (Ec2,S3 etc) required by the app (I want to make this as simple as possible). This batch processing would be done for each cloud. Then some automation would provision services across the according to what would be the cheaper option. This felxibility would prevent "vendor lock-in" and minimiize cost.

- Risk mitigation: disaster recovery (in case one or more services crash) and reduced latency and downtime ( Localizing resources based on geographical separation between different clouds). This would raise a specific flag in the monitoring application in which failed assets would be redeployed and rerouted to a functioning cloud.


Which technologies are well-suited to solve those challenges? (list all relevant)

- Simple processing and analytics : Spark

- Containers and Orchestration : Docker and Kubernetes 

  - Docker : To allow for generation of machine images on the different VPCs
  - Kubernetes : works in conjuction with the monitoring to direct the proper configuration to be used in the terraform script.

- Provisioning and Deployment : Terraform and Kubernetes

  - Terraform : To dynamically adjust the configuration. This is based off how the resources will distributed amongst the clusters
  - Kubernetes : Responsible for the deyployment of the system configuration 

- reroutting + autoscaling : Since the Terraform script will be dynamic I want to properly reroute to a given cloud while allowing it to autoscale to the neccessary number of docker containers for instance.


