# Insight-DevOps-2018 / Multi-Region deployment, load testing and latency based routing.

# General overview of this Insight DevOps project.

Load testing is critical to ensure proper scalability and flexibility. In many applications engineers will utlilize such tools as automatic scaling groups to adjust for different web traffic loads that may occur. In this setup I avoided any vertical or horizontal scaling of my servers. The use case of this project is to adjust network response when web traffic is localized to a particular region. Also it a solution in a failover scenario.

- In this project I used terraform to spin up a cluster of NGINX servers across multiple regions, in this case, east and west coast. 
- To administer the load testing, I used multiple instances to host Jmeter. Jmeter's function here was to generate web traffic requests that would hit the NGINX servers.
- The requests are made to a DNS hostname ( In the case of AWS, this is called route 53 ). Associated with this is a routing table which identifies the relevant IP addresses the requests will be sent to. In addition, the latency routing policy was specified. This is detailed in the code snippet below:

```
resource "aws_route53_record" "cdnv4" {
  zone_id        = "${data.aws_route53_zone.default.zone_id}"
  name           = "${format("%s.%s", var.r53_domain_name, data.aws_route53_zone.default.name)}"
  type           = "A"
  ttl            = "60"
  records        = ["${aws_instance.server.*.public_ip}"]
  set_identifier = "cdn-${var.region}-v4"

  latency_routing_policy {
    region = "${var.region}"
  }
}
```

After building up the NGINX webservers using the included terraform script, you initialize the Jmeter Master and Slave nodes.
First you start the Slave node by running:
```
./jmeter-server
```
Then to start the Master node which will communicate to the slave node to start generating requests (assuming ssh tunneling has been setup) you enter:
```
./jmeter -n -t HTTP_request.jmx -Djava.rmi.server.hostname=http://cdn.multi-region-sv-insight.com -r -l jmeteroutput.csv&
```
# Screencast demo
[Jmeter Run with master & slave](https://youtu.be/wLgNfzp3kpM) \\
[Web Traffic simulation](https://youtu.be/EtSAGjnU0Aw)


# System       
<img alt="System overview" src="Untitled.Diagram.3.png">

# AWS Cloudwatch Monitoring / Jmeter - Master & slave
<img alt="System overview" src="Images/Screen Shot 2018-09-08 at 10.53.00 AM.png">

<img width="892" alt="screen shot 2018-09-04 at 9 01 47 am" src="https://user-images.githubusercontent.com/14183360/45243698-b888f280-b2a9-11e8-937d-242636b12e9e.png">
      

# Response time
Expected increase in latency / response time as a result of increased web traffic.
![response time graph](https://user-images.githubusercontent.com/14183360/45243601-57f9b580-b2a9-11e8-80d3-4034bee483d3.png)

# Resources & links
[Latency based routing](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/routing-policy.html#routing-policy-latency
)


[JMeter on AWS: Performance Testing on Cloud](http://www.testingdiaries.com/jmeter-on-aws/)


[How to build a multi-region active-active architecture on AWS](https://read.acloud.guru/why-and-how-do-we-build-a-multi-region-active-active-architecture-6d81acb7d208)
