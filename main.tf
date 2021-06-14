provider "aws" {
  region  = "sa-east-1"
  profile = "default"
}

resource "aws_security_group" "Acesso-http" {
  name        = "Acesso-http"
  description = "Acesso-http"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

  resource "aws_instance" "teste-vm-01" {

  count         = 1
  ami           = "ami-02e2a5679226e293c"
  instance_type = "t2.micro"
  key_name      = "file(var.keyPath)"
  tags = {
    Name = "VM-01"
  }
  vpc_security_group_ids = ["${aws_security_group.Acesso-http.id}"]

  connection {
    type        = "ssh"
    user        = "admin"
    password    = ""
    private_key = file(var.keyPath)
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y apt-transport-https",
      "sudo apt-get install -y ca-certificates",
      "sudo apt-get install -y curl",
      "sudo apt-get install -y gnupg",
      "sudo apt-get install -y lsb-release git",
      "curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg",
      "sudo echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian buster stable' | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "sudo apt-get update",
      "sudo apt-get install docker-ce docker-ce-cli containerd.io -y",
      "git clone https://github.com/meliuz/devops-apps.git",
      "cd /home/admin/devops-apps/ && make build",
      "cd /home/admin/devops-apps/ && make up ",

    ]
  }
  }
