#!/bin/bash

sed -i '' '/^ssh -i/d' aws-install.sh

cd "${0%/*}"

terraform destroy
