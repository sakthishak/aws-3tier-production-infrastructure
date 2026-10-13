# Retrieve the latest Amazon Linux 2023 AMI
data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# IAM role for secure EC2 administration through Systems Manager
resource "aws_iam_role" "app_ec2_role" {
  name = "aws-3tier-app-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "ec2.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "aws-3tier-app-ec2-role"
    Tier = "application"
  }
}

# Allow the instance to communicate with AWS Systems Manager
resource "aws_iam_role_policy_attachment" "app_ssm" {
  role       = aws_iam_role.app_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach the IAM role to EC2
resource "aws_iam_instance_profile" "app" {
  name = "aws-3tier-app-instance-profile"
  role = aws_iam_role.app_ec2_role.name
}

# Private application server
resource "aws_instance" "app" {
  ami                         = data.aws_ssm_parameter.al2023_ami.value
  instance_type               = "t3.micro"
  key_name                    = "aws key pair"
  subnet_id                   = aws_subnet.app-a.id
  vpc_security_group_ids      = [aws_security_group.app.id]
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.app.name

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  user_data = <<-USERDATA
    #!/bin/bash
    set -euxo pipefail

    id appuser >/dev/null 2>&1 || \
      useradd --system --no-create-home --shell /sbin/nologin appuser

    cat > /opt/health-app.py <<'PYTHON'
    from http.server import BaseHTTPRequestHandler, HTTPServer

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            if self.path == "/health":
                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                self.wfile.write(b'{"status":"healthy"}')
            else:
                self.send_response(200)
                self.send_header("Content-Type", "text/html")
                self.end_headers()
                self.wfile.write(
                    b"<h1>Three-Tier Application</h1>"
                    b"<p>Application server is running.</p>"
                )

        def log_message(self, format, *args):
            print("%s - %s" % (self.address_string(), format % args))

    HTTPServer(("0.0.0.0", 8080), Handler).serve_forever()
    PYTHON

    chown appuser:appuser /opt/health-app.py

    cat > /etc/systemd/system/health-app.service <<'SERVICE'
    [Unit]
    Description=Three-Tier Demo Health Application
    After=network.target

    [Service]
    Type=simple
    User=appuser
    ExecStart=/usr/bin/python3 /opt/health-app.py
    Restart=always
    RestartSec=5

    [Install]
    WantedBy=multi-user.target
    SERVICE

    systemctl daemon-reload
    systemctl enable --now health-app
  USERDATA

  tags = {
    Name = "aws-3tier-app-server"
    Tier = "application"
  }

  depends_on = [
    aws_iam_role_policy_attachment.app_ssm
  ]
}