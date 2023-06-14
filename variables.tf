variable "domain_name" {
type=string
default = "kausicmn.com"
}
variable "certificate_issued_domain"{
type=string
default = "*.kausicmn.com"
}
variable "subdomain" {
    type=string
    default="portfolio.kausicmn.com"
}
variable "api-gateway-subdomain" {
    type=string
    default="counter-api.kausicmn.com"
}