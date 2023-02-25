terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.61.0"
    }

  }
  backend "s3" {
    endpoint   = "storage.yandexcloud.net"
    bucket     = "tf-state-bucket-mentor1"
    region     = "ru-central1-b"
    key        = "lemp.tfstate"
    access_key = "key"
    secret_key = "key"

    skip_region_validation      = true
    skip_credentials_validation = true
  }
}

provider "yandex" {
  token     = "token"
  cloud_id  = "cloud_id"
  folder_id = "folder_id"
  zone      = "ru-central1-b"
}


resource "yandex_vpc_network" "network" {
  name = "network"
}

#Создание первой подсети
resource "yandex_vpc_subnet" "subnet1" {
  name           = "subnet1"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}
#Создание второй подсети
resource "yandex_vpc_subnet" "subnet2" {
  name           = "subnet2"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["192.168.20.0/24"]
}

#Модуль для запуска lemp сервера
module "ya_instance_1" {
  source                = "./modules"
  instance_family_image = "lemp"
  vpc_subnet_id         = yandex_vpc_subnet.subnet1.id
}
#Модуль для запуска lamp сервера
module "ya_instance_2" {
  source                = "./modules"
  instance_family_image = "lamp"
  vpc_subnet_id         = yandex_vpc_subnet.subnet2.id
}

#Создание балансировщика
resource "yandex_lb_network_load_balancer" "lb-web" {
  name = "network-load-balancer"

  listener {
    name = "listener-http"
    port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.web.id
#Проверка доступности хостов, не обязательно. Проверка через TCP а не HTTP.
    healthcheck {
      name = "tcp"
      tcp_options {
        port = 80
#        path = "/"
      }
    }
  }
}

resource "yandex_lb_target_group" "web" {
  name      = "my-target-group"
#Тут настраиваются адреса для балансировщика, берём сеть и адрес из модуля.
  target {
    subnet_id = yandex_vpc_subnet.subnet1.id
    address = module.ya_instance_1.internal_ip_address_vm
  }

  target {
    subnet_id = yandex_vpc_subnet.subnet2.id
    address = module.ya_instance_2.internal_ip_address_vm
  }

}
