terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.61.0"
    }
  }
}
data "yandex_compute_image" "my_image" {
  family = var.instance_family_image
}


resource "yandex_compute_instance" "vm" {
  name = "terraform-${var.instance_family_image}"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20 # Выделение загрузки CPU. Это дешевле. (для проверки)
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.my_image.id
    }
  }

  network_interface {
    subnet_id = var.vpc_subnet_id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/yandex.pub")}"
  }

  scheduling_policy {
    preemptible = true # ВМ прирываема. Это дешевле. (для проверки). Не прод.
  }
}

