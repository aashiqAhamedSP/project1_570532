variable "rgname" {
  type    = string
  default = "jenkin-rg"
}

variable "rgloc" {
  type    = string
  default = "eastus"
}

variable "vnetname" {
  type    = string
  default = "jenkins-vnet"
}

variable "subnetname" {
  type    = string
  default = "subnet1"
}

variable "vmsize" {
  type    = string
  default = "Standard_DS1_v2"
}

variable "uname" {
  type    = string
  default = "vmadmin"
}

variable "ps" {
  type    = string
  default = "Mujahid@2021"
}

variable "jnkscltr" {
  type = list
  default = ["master", "build"]
  
}