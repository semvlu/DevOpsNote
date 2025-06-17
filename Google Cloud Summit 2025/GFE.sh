# Google Front End (GFE) for DDoS mitigation
:'
1. IP adr/VPC -> Reserve ext. static IP adr: 
    * Build ext. cloud to implement anycast on google Load Balancer from the internet

2. Network Endpoint Groups (NEG): 
    * Domain for service/app

3. LB (Load Balancer) config:
	frontend -> ip adr: ext-ip
	backend: neg-demo
	* Enable logging
	* set #request, timeout

4. Test
	curl http://<domain>/<route> --resolve <domain>:<port>:<GFE IP>
'
# e.g.
curl http://example.com/ip --resolve example.com:80:34.13.125.115

# N.B.
# set global over region is better against DDoS attack


